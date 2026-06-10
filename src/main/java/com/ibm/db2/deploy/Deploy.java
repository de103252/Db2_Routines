package com.ibm.db2.deploy;

import java.io.FileNotFoundException;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

public class Deploy {

	public static void main(String[] args) throws Exception {
		Class.forName("com.ibm.db2.jcc.DB2Driver");
		java.sql.Connection c = java.sql.DriverManager.getConnection(
				"jdbc:db2://newg:5045/DALLASD:retrieveMessagesFromServerOnGetMessage=true;", "adcdmst", "he1del");
		try {
			replaceJar(c, "ADCDMST.ROUTINES", "target/routines.jar");
		} catch (SQLException e) {
			if (e.getErrorCode() == -204) {
				installJar(c, "ADCDMST.ROUTINES", "target/routines.jar");
			} else {
				throw e;
			}
		}
		wlmRefresh(c, "DBDGENVJ");
		c.commit();
		c.close();
		System.out.println("Done.");
	}

	private static void installJar(java.sql.Connection c, String jarname, String filename)
			throws SQLException, FileNotFoundException {
		try (CallableStatement s = c.prepareCall("call sqlj.db2_install_jar(?, ?, ?)")) {
			s.setBlob(1, new java.io.BufferedInputStream(new java.io.FileInputStream(filename)));
			s.setString(2, jarname);
			s.setInt(3, 0);
			s.execute();
		}
	}

	private static void replaceJar(java.sql.Connection c, String jarname, String filename)
			throws SQLException, FileNotFoundException {
		try (CallableStatement s = c.prepareCall("call sqlj.db2_replace_jar(?, ?)")) {
			s.setBlob(1, new java.io.BufferedInputStream(new java.io.FileInputStream(filename)));
			s.setString(2, jarname);
			s.execute();
		}
	}

	private static void wlmRefresh(java.sql.Connection c, String environment) throws SQLException {
		try (CallableStatement s = c.prepareCall("call sysproc.wlm_refresh(?, ?, ?, ?")) {
			s.setString(1, environment);
			s.setNull(2, Types.VARCHAR);
			s.registerOutParameter(3, Types.VARCHAR);
			s.registerOutParameter(4, Types.INTEGER);
			s.execute();
		}
	}

}
