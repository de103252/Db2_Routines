package com.ibm.db2.base64;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.Blob;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Base64.Decoder;
import java.util.Base64.Encoder;

/**
 * Base-64 encoding and decoding UDFs for Db2.
 * 
 * To install, compile the code and package it into a Jar file. Install the Jar
 * file into Db2 by running stored procedure SQLJ.DB2_INSTALL_JAR. Easiest way
 * to run it is via Data Studio. As 'Jarname' (second parameter to
 * DB2_INSTALL_JAR), use a name of your choice, either qualified or unqualified.
 * If unqualified, Db2 qualifies it with the current SQLID ("ADCDMST" in the
 * example DDL below).
 * 
 * Create the UDFs by running the following DDL. Replace 'DBCGWLMJ' with the
 * name of the WLM environment for Java routines. Replace 'ADCDMST.BASE64' with
 * the qualified Jar name.
 * <p/>
 * 
 * <pre>
 * create function base64encode(data blob(64M)) 
 * returns clob(64M) ccsid unicode
 * external name 'ADCDMST.BASE64:com.ibm.de103252.db2.base64.Base64.encode'
 * language java 
 * parameter style java 
 * no external action 
 * allow parallel 
 * wlm environment DBCGENVJ 
 * asutime no limit 
 * not secured 
 * deterministic;
 * </pre>
 * 
 * <code>
 * create function base64decode(data clob(64M) ccsid unicode) 
 * returns blob(64M)
 * external name 'ADCDMST.BASE64:com.ibm.de103252.db2.base64.Base64.decode'
 * language java 
 * parameter style java
 * no external action 
 * allow parallel 
 * wlm environment DBCGENVJ 
 * asutime no limit 
 * not secured 
 * deterministic;
 * </code>
 * 
 * To run the UDFs, simply write a SELECT statement such as <code></code> SELECT
 * base64encode(cast('Uli Seelbach' as blob)) from sysibm.sysdummyu; </code>
 * 
 * <code>
 * SELECT base64decode('VWxpIFNlZWxiYWNo') from sysibm.sysdummyu;
 * </code>
 * 
 * @author Uli Seelbach
 *
 */
public class Base64 {
	public static ByteArrayInputStream decode3(Clob data) throws SQLException, IOException {
		try (Connection conn = getConnection()) {
			ByteArrayOutputStream os = new ByteArrayOutputStream();
			Decoder decoder = java.util.Base64.getDecoder();
			InputStream lobStream = data.getAsciiStream();
			try (InputStream is = decoder.wrap(lobStream)) {
				copy(is, os);
			} finally {
				lobStream.close();
			}
			return new ByteArrayInputStream(os.toByteArray());
		}
	}

	public static Blob decode(Clob data) throws SQLException, IOException {
		try (Connection conn = getConnection()) {
			Decoder decoder = java.util.Base64.getDecoder();
			Blob decodedData = conn.createBlob();
			try (InputStream is = decoder.wrap(data.getAsciiStream());
					OutputStream os = new BufferedOutputStream(decodedData.setBinaryStream(1))) {
				copy(is, os);
			}
			return decodedData;
		}
	}

	public static byte[] decode(String data) {
		return java.util.Base64.getDecoder().decode(data);
	}

	public static String encode(byte[] data) {
		return java.util.Base64.getEncoder().encodeToString(data);
	}

	public static Clob encode(Blob data) throws SQLException, IOException {
		try (Connection conn = getConnection()) {
			Encoder encoder = java.util.Base64.getEncoder();
			Clob encodedData = conn.createClob();
			try (InputStream is = new BufferedInputStream(data.getBinaryStream());
					OutputStream os = encoder.wrap(encodedData.setAsciiStream(1))) {
				copy(is, os);
			}
			return encodedData;
		}
	}

	private static Connection getConnection() throws SQLException {
		return DriverManager.getConnection("jdbc:default:connection");
	}

	private static void copy(InputStream source, OutputStream target) throws IOException {
		byte[] buf = new byte[8192];
		int length;
		while ((length = source.read(buf)) > 0) {
			target.write(buf, 0, length);
		}
	}
}
