package com.ibm.db2.csv;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.lang.reflect.Method;
import java.nio.charset.Charset;
import java.nio.charset.UnsupportedCharsetException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVFormat.Builder;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.QuoteMode;
import org.apache.commons.text.StringEscapeUtils;

import com.ibm.jzos.FileAttribute;

public class Unload {

    /**
     * Unload in UTF-8 Excel format with headers.
     * 
     * @param statement
     * @param filename
     * @return
     * @throws SQLException
     * @throws IOException
     */
    public static long unload(String statement, String filename) throws SQLException, IOException {
        return unload(statement, filename, CSVFormat.Predefined.Excel.name(), 1208, 'Y');
    }

    /**
     * Unload the result set of an SQL statement to a file, with the given format
     * and using the given CCSID.
     * 
     * @param statement
     *   A {@code SELECT} statement. 
     * @param filename
     *   Name of destination file.
     * @param formatName
     *   Name of a predefined CSV format (see {@link CSVFormat.Predefined}, or a set of
     *   {@code key=value} settings separated by semicolons to define a custom format.
     * @param ccsid
     *   Output CCSID.
     * @param printHeader
     *   Whether the output file should have a header line.
     * @return
     *   Number of rows unloaded.
     * @throws SQLException
     * @throws IOException
     */
    public static long unload(String statement, String filename, String formatName, int ccsid, char printHeader)
            throws SQLException, IOException {
        try (Connection conn = DriverManager.getConnection("jdbc:default:connection")) {
            conn.setReadOnly(true);
            return unload(conn, statement, filename, formatName, ccsid, printHeader);
        }
    }

    static long unload(Connection conn, String statement, String filename, String formatName, int ccsid,
            char printHeader) throws SQLException, IOException {
        CSVFormat format = getFormat(formatName);
        try (CSVPrinter csvPrinter = new CSVPrinter(openOutputFile(filename, ccsid), format);
                PreparedStatement ps = conn.prepareStatement(statement);
                ResultSet rs = ps.executeQuery()) {
            csvPrinter.printRecords(rs, printHeader == 'Y');
            FileAttribute.setTag(filename, new FileAttribute.Tag((char) ccsid, true));
            return csvPrinter.getRecordCount();
        } catch (SQLException e) {
            if (e.getErrorCode() == -4476) {
                e = new SQLException("Statement must be a query", e.getSQLState(), e.getErrorCode(), e);
            }
            throw e;
        }
    }

    private static CSVFormat getFormat(String formatName) throws SQLException {
        try {
            if (formatName.contains("=")) {
                return buildFormat(formatName);
            } else {
                return CSVFormat.valueOf(formatName);
            }
        } catch (IllegalArgumentException e) {
            throw new SQLException(String.format("Unknown CSV format: %s", formatName));
        } catch (Exception e) {
            throw new SQLException(String.format("Error creating CSV format: %s", e.toString()));
        }
    }

    private static Appendable openOutputFile(String filename, int ccsid) throws SQLException {
        try {
            return new BufferedWriter(
                    new OutputStreamWriter(Files.newOutputStream(Paths.get(filename)), encodingFor(ccsid)));
        } catch (IOException e) {
            throw new SQLException(e);
        }
    }

    private static Charset encodingFor(int ccsid) throws SQLException {
        final String charsetName = switch (ccsid) {
            case 1208 -> "UTF-8";
            case 1200 -> "UTF-16";
            case 819 -> "ISO8859-1";
            case 912 -> "ISO8859-2";
            case 913 -> "ISO8859-3";
            case 915 -> "ISO8859-5";
            case 1089 -> "ISO8859-6";
            case 813 -> "ISO8859-7";
            case 916 -> "ISO8859-8";
            case 920 -> "ISO8859-9";
            case 921 -> "ISO8859-13";
            case 923 -> "ISO8859-15";
            default -> String.format("IBM-%d", ccsid);
        };

        try {
            return Charset.forName(charsetName);
        } catch (UnsupportedCharsetException e) {
            throw new SQLException(String.format("Unsupported CCSID: %s", ccsid));
        }
    }

    private static CSVFormat buildFormat(String formatDesc) throws SQLException {
        Pattern p = Pattern.compile("(?<key>[^=;]+)\\s*=(?<value>(\\\\.|[^;\\\\])*);?");
        Builder csvBuilder = CSVFormat.Builder.create();
        List<Method> methods = Arrays.asList(csvBuilder.getClass().getDeclaredMethods());

        Matcher matcher = p.matcher(formatDesc);
        while (matcher.find()) {
            String key = matcher.group("key").trim();
            String value = matcher.group("value").replace("\\;", ";");
            extracted(csvBuilder, key, value);
        }
        return csvBuilder.get();
    }

    private static void extracted(Builder csvBuilder, String key, String value) throws SQLException {
        try {
            value = StringEscapeUtils.unescapeJava(value);
            switch (key) {
                case "allowMissingColumnNames":
                    csvBuilder.setAllowMissingColumnNames(Boolean.valueOf(value));
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
                    csvBuilder.setHeaderComments(value.split(","));
                    break;
                case "lenientEof":
                    csvBuilder.setLenientEof(Boolean.valueOf(value));
                    break;
                case "maxRows":
                    csvBuilder.setMaxRows(Long.valueOf(value));
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
                    csvBuilder.setSkipHeaderRecord(Boolean.valueOf(value));
                    break;
                case "trailingData":
                    csvBuilder.setTrailingData(Boolean.valueOf(value));
                    break;
                case "trailingDelimiter":
                    csvBuilder.setTrailingDelimiter(Boolean.valueOf(value));
                    break;
                case "trim":
                    csvBuilder.setTrim(Boolean.valueOf(value));
                    break;
                default:
                    throw new SQLException(String.format("Unknown setting: %s", key));
            }
        } catch (NumberFormatException e) {
            throw new SQLException(String.format("Bad value '%s' for key '%s'", value, key));
        } catch (IndexOutOfBoundsException e) {
            throw new SQLException(String.format("Key '%s' for key '%s'", value, key));
        }
    }

    private static char charAt0(String key, String value) throws SQLException {
        if (value.length() != 1) {
            throw new SQLException(String.format("Bad value for key %s, must be exactly one character", key));
        }
        return value.charAt(0);
    }

}
