package com.ibm.db2.date;

import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Implements Db2 stored procedures for date parsing and formatting
 * according to user-specified patterns and locales.
 * 
 * <p>
 * This class provides thread-safe date/time formatting and parsing
 * operations optimized for use within Db2 for z/OS stored procedures.
 * All methods use caching to improve performance for repeated operations
 * with the same patterns and locales.
 * </p>
 *
 * @author Uli Seelbach, IBM Expert Labs
 * @version 2.0
 */
public class Date {

    /**
     * Maximum cache size to prevent memory issues with many unique patterns.
     */
    private static final int MAX_CACHE_SIZE = 100;

    /**
     * Cache for DateTimeFormatter instances to avoid repeated parsing
     * of format patterns. Thread-safe for concurrent access.
     * Uses LinkedHashMap with LRU eviction
     */
    private static final Map<String, DateTimeFormatter> FORMATTER_CACHE = //
            Collections.synchronizedMap(new LinkedHashMap<String, DateTimeFormatter>(
                    MAX_CACHE_SIZE, 0.75f, true) {
                @Override
                protected boolean removeEldestEntry(Map.Entry<String, DateTimeFormatter> eldest) {
                    return size() > MAX_CACHE_SIZE;
                }
            });

    /**
     * Cached result of available locales to avoid repeated computation.
     */
    private static volatile String cachedAvailableLocales = null;

    /**
     * Formats a timestamp using the specified pattern and locale.
     * 
     * <p>
     * This method uses a cache to improve performance when the same
     * pattern and locale combination is used repeatedly.
     * </p>
     *
     * @param ts      the timestamp to format (must not be null)
     * @param pattern the date/time pattern (must not be null or empty)
     * @param locale  the locale language tag (must not be null or empty)
     * @return the formatted date/time string
     * @throws SQLException if the timestamp is null, pattern is invalid,
     *                      locale is invalid, or formatting fails
     */
    public static String format3(Timestamp ts, String pattern, String locale) throws SQLException {
        // Input validation
        if (ts == null) {
            throw new SQLException("Timestamp cannot be null", "22007", -20447);
        }
        if (pattern == null || pattern.trim().isEmpty()) {
            throw new SQLException("Pattern cannot be null or empty", "22007", -20447);
        }
        if (locale == null || locale.trim().isEmpty()) {
            throw new SQLException("Locale cannot be null or empty", "22007", -20447);
        }

        try {
            String cacheKey = pattern + "|" + locale;
            DateTimeFormatter formatter = getOrCreateFormatter(cacheKey, pattern, locale);
            return formatter.format(ts.toLocalDateTime());
        } catch (IllegalArgumentException | DateTimeParseException e) {
            throw new SQLException("Invalid pattern or locale: " + e.getMessage(), "22007", -20447);
        } catch (Exception e) {
            throw new SQLException("Formatting error: " + e.getMessage(), "22007", -20447);
        }
    }

    /**
     * Formats a timestamp using the specified pattern with the default locale.
     * 
     * <p>
     * This method uses a cache to improve performance when the same
     * pattern is used repeatedly.
     * </p>
     *
     * @param ts      the timestamp to format (must not be null)
     * @param pattern the date/time pattern (must not be null or empty)
     * @return the formatted date/time string
     * @throws SQLException if the timestamp is null, pattern is invalid,
     *                      or formatting fails
     */
    public static String format2(Timestamp ts, String pattern) throws SQLException {
        if (ts == null) {
            throw new SQLException("Timestamp cannot be null", "22007", -20447);
        }
        validateNotEmpty(pattern, "Pattern");

        try {
            DateTimeFormatter formatter = getOrCreateFormatter(pattern, pattern, null);
            return formatter.format(ts.toLocalDateTime());
        } catch (IllegalArgumentException | DateTimeParseException e) {
            throw new SQLException("Invalid pattern: " + e.getMessage(), "22007", -20447);
        } catch (Exception e) {
            throw new SQLException("Formatting error: " + e.getMessage(), "22007", -20447);
        }
    }

    /**
     * Parses a date/time string using the specified pattern.
     * 
     * <p>
     * This method uses the modern java.time API for better performance
     * and thread safety compared to SimpleDateFormat.
     * </p>
     *
     * @param tsString the date/time string to parse (must not be null or empty)
     * @param pattern  the date/time pattern (must not be null or empty)
     * @return the parsed timestamp, or null if parsing fails
     * @throws SQLException if input parameters are null or empty
     */
    public static Timestamp parse(String tsString, String pattern) throws SQLException {
        validateNotEmpty(tsString, "Date/time string");
        validateNotEmpty(pattern, "Pattern");

        try {
            DateTimeFormatter formatter = getOrCreateFormatter(pattern, pattern, null);
            LocalDateTime localDateTime = LocalDateTime.parse(tsString, formatter);
            return Timestamp.valueOf(localDateTime);
        } catch (DateTimeParseException e) {
            // Return null for parse failures to maintain backward compatibility
            return null;
        } catch (IllegalArgumentException e) {
            throw new SQLException("Invalid pattern: " + e.getMessage(), "22007", -20447);
        }
    }

    /**
     * Returns a comma-separated list of all available locale language tags.
     * 
     * <p>
     * This method caches the result to avoid repeated computation,
     * as the list of available locales does not change during runtime.
     * </p>
     *
     * @return comma-separated string of locale language tags
     */
    public static String availableLocales() {
        // Use double-checked locking for lazy initialization
        if (cachedAvailableLocales == null) {
            synchronized (Date.class) {
                if (cachedAvailableLocales == null) {
                    cachedAvailableLocales = Arrays.stream(Locale.getAvailableLocales())
                            .map(Locale::toLanguageTag)
                            .sorted()
                            .collect(Collectors.joining(","));
                }
            }
        }
        return cachedAvailableLocales;
    }

    /**
     * Retrieves a DateTimeFormatter from cache or creates a new one.
     * 
     * <p>
     * This method implements a simple cache eviction strategy when
     * the cache size exceeds MAX_CACHE_SIZE.
     * </p>
     *
     * @param cacheKey the cache key
     * @param pattern  the date/time pattern
     * @param locale   the locale language tag (null for default locale)
     * @return the DateTimeFormatter instance
     */
    private static DateTimeFormatter getOrCreateFormatter(String cacheKey, String pattern, String locale) {
        return FORMATTER_CACHE.computeIfAbsent(cacheKey, key -> {
            // Simple cache eviction: clear cache if it grows too large
            if (FORMATTER_CACHE.size() >= MAX_CACHE_SIZE) {
                FORMATTER_CACHE.clear();
            }

            if (locale != null) {
                return DateTimeFormatter.ofPattern(pattern, Locale.forLanguageTag(locale));
            } else {
                return DateTimeFormatter.ofPattern(pattern);
            }
        });
    }

    /**
     * Validates that a parameter value is not null or empty.
     * 
     * @param value the value to validate
     * @param name  the name of the parameter
     * @throws SQLException If the value is null or empty
     */
    private static void validateNotEmpty(String value, String name) throws SQLException {
        if (value == null || value.isEmpty()) {
            throw new SQLException(name + " cannot be null or empty", "22007", -20447);
        }
    }
}
