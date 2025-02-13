package com.ibm.db2.csv;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVFormat.Builder;
import org.apache.commons.csv.CSVPrinter;

import com.ibm.jzos.FileAttribute;

public class Unload {
	public static long unload(String statement, String filename, String formatName, int printHeader)
			throws SQLException, IOException {
		CSVFormat format = getFormat(formatName);
		try (Connection conn = DriverManager.getConnection("jdbc:default:connection");
				CSVPrinter csvPrinter = new CSVPrinter(openOutputFile(filename), format);
				PreparedStatement ps = conn.prepareStatement(statement);
				ResultSet rs = ps.executeQuery()) {
			csvPrinter.printRecords(rs, printHeader != 0);
			FileAttribute.setTag(filename, new FileAttribute.Tag((char) 1208, true));
			return csvPrinter.getRecordCount();
		}
	}

	private static CSVFormat getFormat(String formatName) throws SQLException {
		try {
			return CSVFormat.valueOf(formatName);
		} catch (IllegalArgumentException e) {
			throw new SQLException("Unknown CSV format");
		}
	}

	private static Appendable openOutputFile(String filename) throws IOException {
		try {
			return new BufferedWriter(
					new OutputStreamWriter(
							Files.newOutputStream(Paths.get(filename)), "utf-8"));
		} catch (UnsupportedEncodingException e) {
			throw new RuntimeException(e);
		}
	}

	private static void buildFormat(String formatDesc) {
		Pattern p = Pattern.compile("\\G(\\w+)\\s*=\\s*([^;]+);\\s*");
		Matcher m = p.matcher(formatDesc.replace("\\;", "\u241E"));
		int lastMatchPos = 0;
		Class<CSVFormat.Builder> c = CSVFormat.Builder.class;
		Builder b = Builder.create();
		while (m.find()) {
			String key = m.group(1);
			String value = m.group(2).replace('\u241E', ';');
			lastMatchPos = m.end();
		}
	}
}
