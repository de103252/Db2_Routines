package com.ibm.db2.csv;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.charset.UnsupportedCharsetException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVFormat.Builder;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.QuoteMode;
import org.apache.commons.text.StringEscapeUtils;

import com.ibm.jzos.FileAttribute;
import com.ibm.jzos.FileFactory;
import com.ibm.jzos.RcException;
import com.ibm.jzos.ZFile;

/**
 * Utility class for unloading Db2 query results to CSV files on z/OS.
 * <p>
 * This class provides methods to execute SQL SELECT statements and write the
 * results to CSV files. It can be invoked as a Db2 stored procedure or used
 * via a command-line interface for standalone execution.
 * </p>
 * <p>
 * Features:
 * <ul>
 * <li>Configurable CSV formats and character encodings (CCSID)</li>
 * <li>Support for USS files and MVS datasets through DD names</li>
 * <li>GNU/Unix style command-line options for standalone execution</li>
 * <li>Predefined CSV formats (Excel, RFC4180, etc.) and custom format specifications</li>
 * </ul>
 * </p>
 *
 * @author IBM
 * @version 1.2
 */
public final class Unload {

    /** Default JDBC URL for stored procedure context */
    private static String url = "jdbc:default:connection";

    /**
     * Compiled regex pattern for parsing custom format specifications (cached for
     * performance)
     */
    private static final Pattern FORMAT_PATTERN = Pattern.compile("(?<key>[^=;]+)\\s*=(?<value>(\\\\.|[^;\\\\])*);?");

    /** CCSID to encoding name mapping for common z/OS code pages */
    private static final Map<Integer, String> CCSID_ENCODING_MAP = Map.of(
            1208, "UTF-8",
            1200, "UTF-16",
            819, "ISO8859-1",
            912, "ISO8859-2",
            913, "ISO8859-3",
            915, "ISO8859-5",
            1089, "ISO8859-6",
            813, "ISO8859-7",
            916, "ISO8859-8",
            920, "ISO8859-9");

    /** Db2 error code indicating statement is not a query */
    private static final int SQLCODE_NOT_A_QUERY = -4476;

    /** Default CCSID for UTF-8 encoding */
    private static final int DEFAULT_CCSID = 1208;

    /** Default CSV format name */
    private static final String DEFAULT_FORMAT = "Excel";

    /**
     * Private constructor to prevent instantiation of utility class.
     */
    private Unload() {
        throw new UnsupportedOperationException("Utility class cannot be instantiated");
    }

    /**
     * Unload query results in UTF-8 Excel format with headers.
     * <p>
     * This is a convenience method that uses sensible defaults:
     * UTF-8 encoding (CCSID 1208), Excel CSV format, and includes headers.
     * </p>
     *
     * @param statement SQL SELECT statement to execute
     * @param filename  Name of destination file (USS path or //'DATA.SET.NAME')
     * @return Number of rows unloaded
     * @throws SQLException             If database access error occurs or statement
     *                                  is not a query
     * @throws IOException              If file I/O error occurs
     * @throws IllegalArgumentException If statement or filename is null or empty
     */
    public static long unload(String statement, String filename) throws SQLException, IOException {
        validateNotEmpty(statement, "SQL statement");
        validateNotEmpty(filename, "filename");
        return unload(statement, filename, DEFAULT_FORMAT, DEFAULT_CCSID, "Y");
    }

    /**
     * Unload query results to a file with specified format and encoding.
     * <p>
     * This method executes the SQL statement and writes results to the specified
     * file using the given CSV format and character encoding.
     * </p>
     *
     * @param statement   SQL SELECT statement to execute
     * @param filename    Name of destination file (USS path or //'DATA.SET.NAME')
     * @param formatName  Name of predefined CSV format (see
     *                    {@link CSVFormat.Predefined}),
     *                    or custom format as {@code key=value} pairs separated by
     *                    semicolons
     * @param ccsid       Output CCSID (Coded Character Set Identifier)
     * @param printHeader Whether to include column headers ("Y" or "N")
     * @return Number of rows unloaded
     * @throws SQLException             If database access error occurs or statement
     *                                  is not a query
     * @throws IOException              If file I/O error occurs
     * @throws IllegalArgumentException If any required parameter is null or invalid
     */
    public static long unload(String statement, String filename, String formatName, int ccsid, String printHeader)
            throws SQLException, IOException {
        validateNotEmpty(statement, "SQL statement");
        validateNotEmpty(filename, "filename");
        validateNotEmpty(formatName, "format name");
        validateCcsid(ccsid);

        try (Connection conn = DriverManager.getConnection(url)) {
            conn.setReadOnly(true);
            return unload(conn, statement, filename, formatName, ccsid, "Y".equalsIgnoreCase(printHeader));
        }
    }

    /**
     * Unload query results with MVS dataset allocation support.
     * <p>
     * This method supports dynamic allocation of MVS datasets when the filename
     * starts with "//". The fileMode parameter specifies dataset attributes
     * (e.g., "shr" for shared access, "old" for exclusive access).
     * </p>
     *
     * @param statement   SQL SELECT statement to execute
     * @param filename    Name of destination file or MVS dataset (//dataset.name)
     * @param fileMode    Dataset allocation mode (e.g., "shr", "old", "new")
     * @param formatName  CSV format specification
     * @param ccsid       Output CCSID
     * @param printHeader Whether to include column headers ("Y" or "N")
     * @return Number of rows unloaded
     * @throws SQLException             If database access error occurs
     * @throws IOException              If file I/O error occurs
     * @throws RcException              If dataset allocation fails
     * @throws IllegalArgumentException If any required parameter is null or invalid
     */
    public static long unload(String statement, String filename, String fileMode, String formatName, int ccsid,
            String printHeader) throws SQLException, IOException {
        validateNotEmpty(statement, "SQL statement");
        validateNotEmpty(filename, "filename");
        validateNotEmpty(formatName, "format name");
        validateCcsid(ccsid);

        if (filename.startsWith("//")) {
            return unloadToMvsDataset(statement, filename, fileMode, formatName, ccsid, printHeader);
        }
        return unload(statement, filename, formatName, ccsid, printHeader);
    }

    /**
     * Internal method to unload with an existing connection.
     * <p>
     * This method performs the actual unload operation using a provided connection.
     * It's package-private to allow testing with mock connections.
     * </p>
     *
     * @param conn        Database connection
     * @param statement   SQL SELECT statement
     * @param filename    Destination file name
     * @param formatName  CSV format specification
     * @param ccsid       Output CCSID
     * @param printHeader Whether to include headers
     * @return Number of rows unloaded
     * @throws SQLException If database access error occurs
     * @throws IOException  If file I/O error occurs
     */
    static long unload(Connection conn, String statement, String filename, String formatName, int ccsid,
            boolean printHeader) throws SQLException, IOException {
        CSVFormat format = getFormat(formatName);

        try (CSVPrinter csvPrinter = new CSVPrinter(openOutputFile(filename, ccsid), format);
                PreparedStatement ps = conn.prepareStatement(statement);
                ResultSet rs = ps.executeQuery()) 
        {
            csvPrinter.printRecords(rs, printHeader);
            setFileTag(filename, ccsid);
            return csvPrinter.getRecordCount();
        } catch (SQLException e) {
            throw enhanceSqlException(e);
        }
    }

    /**
     * Unload to an MVS dataset with dynamic allocation.
     *
     * @param statement   SQL SELECT statement
     * @param filename    MVS dataset name (starting with "//")
     * @param fileMode    Dataset allocation mode
     * @param formatName  CSV format specification
     * @param ccsid       Output CCSID
     * @param printHeader Whether to include headers
     * @return Number of rows unloaded
     * @throws SQLException If database access error occurs
     * @throws IOException  If file I/O error occurs
     * @throws RcException  If dataset allocation fails
     */
    private static long unloadToMvsDataset(String statement, String filename, String fileMode,
            String formatName, int ccsid, String printHeader) throws SQLException, IOException {
        String ddname = ZFile.allocDummyDDName();
        String ssDdname = "//DD:" + ddname;
        String datasetName = filename.substring(2);
        String allocCmd = String.format("alloc fi(%s) da(%s) reuse %s", ddname, datasetName,
                fileMode != null ? fileMode : "");

        try {
            ZFile.bpxwdyn(allocCmd);
            return unload(statement, ssDdname, formatName, ccsid, printHeader);
        } finally {
            try {
                ZFile.bpxwdyn("free fi(" + ddname + ") msg(2)");
            } catch (RcException e) {
                // Log but don't fail on cleanup error
                System.err.println("Warning: Failed to free DD name " + ddname + ": " + e.getMessage());
            }
        }
    }

    /**
     * Get CSV format from format name or custom specification.
     *
     * @param formatName Predefined format name or custom format string
     * @return Configured CSVFormat instance
     * @throws SQLException If format is invalid or unknown
     */
    private static CSVFormat getFormat(String formatName) throws SQLException {
        try {
            if (formatName.contains("=")) {
                return buildFormat(formatName);
            } else {
                return CSVFormat.valueOf(formatName);
            }
        } catch (IllegalArgumentException e) {
            throw new SQLException(String.format("Unknown CSV format: %s", formatName), e);
        } catch (Exception e) {
            throw new SQLException(String.format("Error creating CSV format: %s", e.getMessage()), e);
        }
    }

    /**
     * Open output file with specified encoding.
     *
     * @param filename File name or DD name
     * @param ccsid    Character encoding CCSID
     * @return Appendable writer for CSV output
     * @throws SQLException If file cannot be opened
     */
    private static Appendable openOutputFile(String filename, int ccsid) throws SQLException {
        try {
            return FileFactory.newBufferedWriter(filename, encodingFor(ccsid));
        } catch (IOException e) {
            throw new SQLException("Failed to open output file: " + filename, e);
        }
    }

    /**
     * Get Charset for CCSID.
     *
     * @param ccsid Character encoding CCSID
     * @return Charset instance
     * @throws SQLException If CCSID is not supported
     */
    private static Charset charsetFor(int ccsid) throws SQLException {
        try {
            return Charset.forName(encodingFor(ccsid));
        } catch (UnsupportedCharsetException e) {
            throw new SQLException(String.format("Unsupported CCSID: %d", ccsid), e);
        }
    }

    /**
     * Get encoding name for CCSID.
     * <p>
     * This method maps common z/OS CCSIDs to Java encoding names.
     * For unmapped CCSIDs, it returns "IBM-{ccsid}" format.
     * </p>
     *
     * @param ccsid Character encoding CCSID
     * @return Java encoding name
     */
    private static String encodingFor(int ccsid) {
        return CCSID_ENCODING_MAP.getOrDefault(ccsid, String.format("IBM-%d", ccsid));
    }

    /**
     * Build custom CSV format from format description string.
     * <p>
     * Format description consists of key=value pairs separated by semicolons.
     * Values can contain escaped characters using Java escape sequences.
     * </p>
     *
     * @param formatDesc Format description string
     * @return Configured CSVFormat instance
     * @throws SQLException If format description is invalid
     */
    private static CSVFormat buildFormat(String formatDesc) throws SQLException {
        Builder csvBuilder = CSVFormat.Builder.create();
        Matcher matcher = FORMAT_PATTERN.matcher(formatDesc);

        while (matcher.find()) {
            String key = matcher.group("key").trim();
            String value = matcher.group("value").replace("\\;", ";");
            setProperty(csvBuilder, key, value);
        }

        return csvBuilder.get();
    }

    /**
     * Set a property on the CSV format builder.
     *
     * @param csvBuilder CSV format builder
     * @param key        Property name
     * @param value      Property value
     * @throws SQLException If property name is unknown or value is invalid
     */
    private static void setProperty(Builder csvBuilder, String key, String value) throws SQLException {
        try {
            value = StringEscapeUtils.unescapeJava(value);

            switch (key) {
                case "allowMissingColumnNames":
                    csvBuilder.setAllowMissingColumnNames(Boolean.parseBoolean(value));
                    break;
                case "commentMarker":
                    csvBuilder.setCommentMarker(charAt0(key, value));
                    break;
                case "delimiter":
                    csvBuilder.setDelimiter(value);
                    break;
                case "escape":
                    csvBuilder.setEscape(charAt0(key, value));
                    break;
                case "headerComments":
                    csvBuilder.setHeaderComments((Object[]) value.split(","));
                    break;
                case "lenientEof":
                    csvBuilder.setLenientEof(Boolean.parseBoolean(value));
                    break;
                case "maxRows":
                    csvBuilder.setMaxRows(Long.parseLong(value));
                    break;
                case "nullString":
                    csvBuilder.setNullString(value);
                    break;
                case "quote":
                    csvBuilder.setQuote(charAt0(key, value));
                    break;
                case "quoteMode":
                    csvBuilder.setQuoteMode(QuoteMode.valueOf(value));
                    break;
                case "recordSeparator":
                    csvBuilder.setRecordSeparator(value);
                    break;
                case "skipHeaderRecord":
                    csvBuilder.setSkipHeaderRecord(Boolean.parseBoolean(value));
                    break;
                case "trailingData":
                    csvBuilder.setTrailingData(Boolean.parseBoolean(value));
                    break;
                case "trailingDelimiter":
                    csvBuilder.setTrailingDelimiter(Boolean.parseBoolean(value));
                    break;
                case "trim":
                    csvBuilder.setTrim(Boolean.parseBoolean(value));
                    break;
                default:
                    throw new SQLException(String.format("Unknown CSV format setting: %s", key));
            }
        } catch (NumberFormatException e) {
            throw new SQLException(String.format("Invalid numeric value '%s' for setting '%s'", value, key), e);
        } catch (IllegalArgumentException e) {
            throw new SQLException(String.format("Invalid value '%s' for setting '%s': %s",
                    value, key, e.getMessage()), e);
        }
    }

    /**
     * Extract single character from string value.
     *
     * @param key   Property name (for error messages)
     * @param value String value
     * @return First character of value
     * @throws SQLException If value is not exactly one character
     */
    private static char charAt0(String key, String value) throws SQLException {
        if (value == null || value.length() != 1) {
            throw new SQLException(String.format(
                    "Setting '%s' requires exactly one character, got: %s",
                    key, value == null ? "null" : "'" + value + "'"));
        }
        return value.charAt(0);
    }

    /**
     * Set file tag for USS file.
     *
     * @param filename File name
     * @param ccsid    Character encoding CCSID
     */
    private static void setFileTag(String filename, int ccsid) {
        if (!filename.startsWith("//")) {
            try {
                FileAttribute.setTag(filename, new FileAttribute.Tag((char) ccsid, true));
            } catch (Exception e) {
                // Silently ignore tagging errors for compatibility
                System.err.println("Warning: Failed to set file tag for " + filename + ": " + e.getMessage());
            }
        }
    }

    /**
     * Enhance SQLException with more descriptive message.
     *
     * @param e Original SQLException
     * @return Enhanced SQLException or original if no enhancement needed
     */
    private static SQLException enhanceSqlException(SQLException e) {
        if (e.getErrorCode() == SQLCODE_NOT_A_QUERY) {
            return new SQLException(
                    "Statement must be a SELECT query (SQLCODE -4476)",
                    e.getSQLState(),
                    e.getErrorCode(),
                    e);
        }
        return e;
    }

    /**
     * Validate that string parameter is not null or empty.
     *
     * @param value     Parameter value
     * @param paramName Parameter name for error message
     * @throws IllegalArgumentException If value is null or empty
     */
    private static void validateNotEmpty(String value, String paramName) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException(paramName + " cannot be null or empty");
        }
    }

    /**
     * Validate CCSID value.
     *
     * @param ccsid CCSID value
     * @throws IllegalArgumentException If CCSID is invalid
     */
    private static void validateCcsid(int ccsid) {
        if (ccsid < 1 || ccsid > 65535) {
            throw new IllegalArgumentException("CCSID must be between 1 and 65535, got: " + ccsid);
        }
    }

    /**
     * Main method for command-line execution using Apache Commons CLI.
     * <p>
     * Supports GNU/Unix style command-line options with both short and long forms.
     * SQL statement is read from standard input.
     * </p>
     *
     * @param args Command-line arguments
     */
    public static void main(String[] args) {
        Options options = createOptions();
        CommandLineParser parser = new DefaultParser();
        
        try {
            CommandLine cmd = parser.parse(options, args);
            
            // Check for help option
            if (cmd.hasOption("help")) {
                printHelp(options);
                System.exit(0);
            }
            
            // Validate required options
            if (!cmd.hasOption("u") || !cmd.hasOption("o")) {
                System.err.println("Error: Missing required options.");
                System.err.println();
                printHelp(options);
                System.exit(8);
            }
            
            // Extract option values
            url = cmd.getOptionValue("u");
            String outputFile = cmd.getOptionValue("o");
            String format = cmd.getOptionValue("f", DEFAULT_FORMAT);
            int ccsid = DEFAULT_CCSID;
            
            // Parse CCSID if provided
            if (cmd.hasOption("c")) {
                try {
                    ccsid = Integer.parseInt(cmd.getOptionValue("c"));
                    validateCcsid(ccsid);
                } catch (NumberFormatException e) {
                    System.err.println("Error: Invalid CCSID value '" + cmd.getOptionValue("c") + "'. Must be an integer between 1 and 65535.");
                    System.exit(8);
                } catch (IllegalArgumentException e) {
                    System.err.println("Error: " + e.getMessage());
                    System.exit(8);
                }
            }
            
            // Determine whether to print headers (default is true, unless --no-headers is specified)
            String printHeaders = cmd.hasOption("h") ? "N" : "Y";
            
            // Read SQL from stdin
            String sql = readFully(System.in);
            
            // Execute unload
            long rowCount = unload(sql, outputFile, format, ccsid, printHeaders);
            System.out.println("Successfully unloaded " + rowCount + " rows to " + outputFile);
            System.exit(0);
            
        } catch (ParseException e) {
            System.err.println("Error parsing command-line arguments: " + e.getMessage());
            System.err.println();
            printHelp(options);
            System.exit(8);
        } catch (IOException e) {
            System.err.println("I/O error: " + e.getMessage());
            e.printStackTrace(System.err);
            System.exit(16);
        } catch (SQLException e) {
            System.err.println("SQL error: " + e.getMessage());
            System.err.println("SQLCODE: " + e.getErrorCode());
            System.err.println("SQLSTATE: " + e.getSQLState());
            e.printStackTrace(System.err);
            System.exit(12);
        } catch (Exception e) {
            System.err.println("Unexpected error: " + e.getMessage());
            e.printStackTrace(System.err);
            System.exit(20);
        }
    }
    
    /**
     * Create command-line options for the application.
     *
     * @return Options object with all defined command-line options
     */
    private static Options createOptions() {
        Options options = new Options();
        
        options.addOption(Option.builder("u")
                .longOpt("jdbc-url")
                .hasArg()
                .argName("URL")
                .desc("JDBC connection URL (required)")
                .required(false)  // We'll validate manually for better error messages
                .build());
        
        options.addOption(Option.builder("o")
                .longOpt("output-file")
                .hasArg()
                .argName("FILE")
                .desc("Output CSV file path (required)")
                .required(false)  // We'll validate manually for better error messages
                .build());
        
        options.addOption(Option.builder("f")
                .longOpt("format")
                .hasArg()
                .argName("FORMAT")
                .desc("CSV format name (default: Excel). Predefined formats: Default, Excel, InformixUnload, MySQL, Oracle, PostgreSQL, RFC4180, TDF. Or custom format as key=value pairs separated by semicolons.")
                .build());
        
        options.addOption(Option.builder("c")
                .longOpt("ccsid")
                .hasArg()
                .argName("CCSID")
                .desc("Output CCSID/character encoding (default: 1208 for UTF-8)")
                .build());
        
        options.addOption(Option.builder("h")
                .longOpt("no-headers")
                .hasArg(false)
                .desc("Suppress column headers in output (default: headers are included)")
                .build());
        
        options.addOption(Option.builder()
                .longOpt("help")
                .hasArg(false)
                .desc("Display this help message")
                .build());
        
        return options;
    }
    
    /**
     * Print help message with usage information.
     *
     * @param options The command-line options to display
     */
    private static void printHelp(Options options) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.setWidth(100);
        
        String header = "\nUnload Db2 query results to CSV files.\n" +
                        "SQL SELECT statement is read from standard input.\n\n" +
                        "Options:\n";
        
        String footer = "\nExamples:\n" +
                        "  echo \"SELECT * FROM SYSIBM.SYSTABLES\" | \\\n" +
                        "    java " + Unload.class.getName() + " -u jdbc:db2://localhost:5035/SAMPLE -o output.csv\n\n" +
                        "  echo \"SELECT * FROM SYSIBM.SYSTABLES\" | \\\n" +
                        "    java " + Unload.class.getName() + " --jdbc-url jdbc:db2://localhost:5035/SAMPLE \\\n" +
                        "         --output-file output.csv --format RFC4180 --ccsid 1208 --no-headers\n";
        
        formatter.printHelp("java " + Unload.class.getName(), header, options, footer, true);
    }

    /**
     * Read entire input stream into string.
     * <p>
     * This method uses BufferedReader for better performance with large inputs.
     * It properly handles character encoding using UTF-8.
     * </p>
     *
     * @param in Input stream
     * @return Complete input as string
     * @throws IOException If read error occurs
     */
    private static String readFully(InputStream in) throws IOException {
        StringBuilder sb = new StringBuilder(8192);
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(in, StandardCharsets.UTF_8))) {
            char[] buffer = new char[8192];
            int charsRead;
            while ((charsRead = reader.read(buffer)) != -1) {
                sb.append(buffer, 0, charsRead);
            }
        }
        return sb.toString();
    }

}

// Made with Bob
