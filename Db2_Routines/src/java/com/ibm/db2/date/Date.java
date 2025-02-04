package com.ibm.db2.date;

import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

import com.ibm.db2.jcc.DBTimestamp;

public class Date {
    public static String format3(Timestamp ts, String pattern, String locale) throws SQLException {
        try {
        	return DateTimeFormatter.ofPattern(pattern, Locale.forLanguageTag(locale)).format(ts.toLocalDateTime());
        } catch (IllegalArgumentException e) {
            throw new SQLException(e.getMessage(), "22007", -20447);
        }
    }

    public static String format2(Timestamp ts, String pattern) throws SQLException {
        try {
        	return DateTimeFormatter.ofPattern(pattern).format(ts.toLocalDateTime());
        } catch (IllegalArgumentException e) {
            throw new SQLException(e.getMessage(), "22007", -20447);
        }
    }

    public static DBTimestamp parse(String tsString, String pattern) {
        try {
            return new DBTimestamp(new SimpleDateFormat(pattern).parse(tsString).getTime());
        } catch (ParseException e) {
            return null;
        }
    }
}
