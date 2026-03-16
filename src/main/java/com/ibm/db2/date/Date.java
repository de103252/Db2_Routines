package com.ibm.db2.date;

import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

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

	public static Timestamp parse(String tsString, String pattern) {
		try {
			return new Timestamp(new SimpleDateFormat(pattern).parse(tsString).getTime());
		} catch (ParseException e) {
			return null;
		}
	}

	public static String availableLocales() {
		return Arrays.asList(Locale.getAvailableLocales()).stream().map(Locale::toLanguageTag).collect(Collectors.joining(","));
	}
}
