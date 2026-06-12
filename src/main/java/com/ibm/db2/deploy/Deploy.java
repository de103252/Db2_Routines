package com.ibm.db2.deploy;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Types;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

/**
 * DB2 for z/OS JAR Deployment Utility
 *
 * This utility deploys JAR files to DB2 for z/OS using the SQLJ stored procedures.
 * It supports both installing new JARs and replacing existing ones, with automatic
 * WLM environment refresh.
 */
public class Deploy {

	public static void main(String[] args) {
		Options options = createOptions();
		
		try {
			CommandLineParser parser = new DefaultParser();
			CommandLine cmd = parser.parse(options, args);
			
			// Display help if requested
			if (cmd.hasOption("h")) {
				printHelp(options);
				System.exit(0);
			}
			
			// Validate required parameters
			validateRequiredOptions(cmd, options);
			
			// Extract parameters
			String jdbcUrl = cmd.getOptionValue("url");
			String username = cmd.getOptionValue("user");
			String password = cmd.getOptionValue("password");
			String jarFile = cmd.getOptionValue("jar");
			String jarId = cmd.getOptionValue("id");
			String wlmEnv = cmd.getOptionValue("wlm");
			
			// Validate JAR file exists
			if (!Files.exists(Paths.get(jarFile))) {
				System.err.println("ERROR: JAR file not found: " + jarFile);
				System.exit(1);
			}
			
			// Execute deployment
			deployJar(jdbcUrl, username, password, jarFile, jarId, wlmEnv);
			
		} catch (ParseException e) {
			System.err.println("ERROR: " + e.getMessage());
			System.err.println();
			printHelp(options);
			System.exit(1);
		} catch (Exception e) {
			System.err.println("ERROR: Deployment failed - " + e.getMessage());
			e.printStackTrace();
			System.exit(1);
		}
	}
	
	/**
	 * Creates command-line options for the deployment utility
	 */
	private static Options createOptions() {
		Options options = new Options();
		
		options.addOption(Option.builder("h")
				.longOpt("help")
				.desc("Display this help message")
				.build());
		
		options.addOption(Option.builder("url")
				.longOpt("jdbc-url")
				.hasArg()
				.argName("JDBC_URL")
				.desc("JDBC connection URL for DB2 z/OS (e.g., jdbc:db2://host:port/database)")
				.required()
				.build());
		
		options.addOption(Option.builder("u")
				.longOpt("user")
				.hasArg()
				.argName("USERNAME")
				.desc("Database username for authentication")
				.required()
				.build());
		
		options.addOption(Option.builder("p")
				.longOpt("password")
				.hasArg()
				.argName("PASSWORD")
				.desc("Database password for authentication")
				.required()
				.build());
		
		options.addOption(Option.builder("j")
				.longOpt("jar")
				.hasArg()
				.argName("JAR_FILE")
				.desc("Path to the local JAR file to deploy")
				.required()
				.build());
		
		options.addOption(Option.builder("i")
				.longOpt("id")
				.hasArg()
				.argName("JAR_ID")
				.desc("Target database JAR identifier (e.g., SCHEMA.JARNAME)")
				.required()
				.build());
		
		options.addOption(Option.builder("w")
				.longOpt("wlm")
				.hasArg()
				.argName("WLM_ENV")
				.desc("WLM environment name to refresh after deployment")
				.required()
				.build());
		
		return options;
	}
	
	/**
	 * Validates that all required options are present
	 */
	private static void validateRequiredOptions(CommandLine cmd, Options options) throws ParseException {
		for (Option option : options.getOptions()) {
			if (option.isRequired() && !cmd.hasOption(option.getOpt())) {
				throw new ParseException("Missing required option: --" + option.getLongOpt());
			}
		}
	}
	
	/**
	 * Prints help information
	 */
	private static void printHelp(Options options) {
		HelpFormatter formatter = new HelpFormatter();
		formatter.setWidth(100);
		
		System.out.println("DB2 for z/OS JAR Deployment Utility");
		System.out.println("===================================");
		System.out.println();
		
		formatter.printHelp("java -jar deploy.jar [OPTIONS]",
				"\nDeploys a JAR file to DB2 for z/OS and refreshes the WLM environment.\n\nOptions:",
				options,
				"\nExamples:\n" +
				"  Basic deployment:\n" +
				"    java -jar deploy.jar \\\n" +
				"      --jdbc-url jdbc:db2://mainframe:5045/DALLASD \\\n" +
				"      --user myuser --password mypass \\\n" +
				"      --jar target/routines.jar \\\n" +
				"      --id MYSCHEMA.ROUTINES \\\n" +
				"      --wlm DBDGENVJ\n\n" +
				"  Maven execution:\n" +
				"    mvn exec:java -Dexec.mainClass=\"com.ibm.db2.deploy.Deploy\" \\\n" +
				"      -Dexec.args=\"--jdbc-url jdbc:db2://host:port/db --user usr --password pwd \\\n" +
				"                   --jar target/routines.jar --id SCHEMA.JAR --wlm WLMENV\"\n\n" +
				"Exit Codes:\n" +
				"  0 - Success\n" +
				"  1 - Error (invalid parameters, connection failure, or deployment error)\n",
				true);
	}
	
	/**
	 * Performs the JAR deployment to DB2 for z/OS
	 */
	private static void deployJar(String jdbcUrl, String username, String password,
			String jarFile, String jarId, String wlmEnv) throws Exception {
		
		// Load DB2 JDBC driver
		Class.forName("com.ibm.db2.jcc.DB2Driver");
		
		System.out.println("Connecting to database...");
		System.out.println("  JDBC URL: " + jdbcUrl);
		System.out.println("  Username: " + username);
		
		Connection conn = null;
		try {
			conn = DriverManager.getConnection(jdbcUrl, username, password);
			conn.setAutoCommit(false);
			
			System.out.println("Connected successfully.");
			System.out.println();
			System.out.println("Deploying JAR file...");
			System.out.println("  Local file: " + jarFile);
			System.out.println("  Target ID:  " + jarId);
			
			// Try to replace first, install if not found
			try {
				System.out.println("  Attempting to replace existing JAR...");
				replaceJar(conn, jarId, jarFile);
				System.out.println("  JAR replaced successfully.");
			} catch (SQLException e) {
				if (e.getErrorCode() == -204) {
					System.out.println("  JAR not found, installing new JAR...");
					installJar(conn, jarId, jarFile);
					System.out.println("  JAR installed successfully.");
				} else {
					throw e;
				}
			}
			
			System.out.println();
			System.out.println("Refreshing WLM environment: " + wlmEnv);
			wlmRefresh(conn, wlmEnv);
			System.out.println("  WLM environment refreshed successfully.");
			
			conn.commit();
			System.out.println();
			System.out.println("Deployment completed successfully.");
			
		} catch (SQLException e) {
			if (conn != null) {
				try {
					conn.rollback();
					System.err.println("Transaction rolled back due to error.");
				} catch (SQLException rollbackEx) {
					System.err.println("Failed to rollback transaction: " + rollbackEx.getMessage());
				}
			}
			throw new SQLException("Database error: " + e.getMessage() +
					" (SQLCODE: " + e.getErrorCode() + ", SQLSTATE: " + e.getSQLState() + ")", e);
		} finally {
			if (conn != null) {
				try {
					conn.close();
					System.out.println("Database connection closed.");
				} catch (SQLException e) {
					System.err.println("Warning: Failed to close connection: " + e.getMessage());
				}
			}
		}
	}

	/**
	 * Installs a new JAR file into DB2 for z/OS
	 */
	private static void installJar(Connection conn, String jarId, String jarFile)
			throws SQLException, FileNotFoundException {
		try (CallableStatement stmt = conn.prepareCall("call sqlj.db2_install_jar(?, ?, ?)")) {
			stmt.setBlob(1, new java.io.BufferedInputStream(new java.io.FileInputStream(jarFile)));
			stmt.setString(2, jarId);
			stmt.setInt(3, 0);
			stmt.execute();
		}
	}

	/**
	 * Replaces an existing JAR file in DB2 for z/OS
	 */
	private static void replaceJar(Connection conn, String jarId, String jarFile)
			throws SQLException, FileNotFoundException {
		try (CallableStatement stmt = conn.prepareCall("call sqlj.db2_replace_jar(?, ?)")) {
			stmt.setBlob(1, new java.io.BufferedInputStream(new java.io.FileInputStream(jarFile)));
			stmt.setString(2, jarId);
			stmt.execute();
		}
	}

	/**
	 * Refreshes the specified WLM environment
	 */
	private static void wlmRefresh(Connection conn, String wlmEnv) throws SQLException {
		try (CallableStatement stmt = conn.prepareCall("call sysproc.wlm_refresh(?, ?, ?, ?)")) {
			stmt.setString(1, wlmEnv);
			stmt.setNull(2, Types.VARCHAR);
			stmt.registerOutParameter(3, Types.VARCHAR);
			stmt.registerOutParameter(4, Types.INTEGER);
			stmt.execute();
			
			// Check for warnings or errors from WLM refresh
			String message = stmt.getString(3);
			int returnCode = stmt.getInt(4);
			
			if (returnCode != 0) {
				System.err.println("  Warning: WLM refresh returned code " + returnCode +
						(message != null ? ": " + message : ""));
			}
		}
	}

}
