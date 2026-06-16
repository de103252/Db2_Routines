package com.ibm.db2.regex;

import java.sql.SQLException;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

public class Regex {

    private static final int MAX_PATTERNS_TO_CACHE = 100;
    @SuppressWarnings("serial")
    private static final Map<String, Pattern> patternCache = //
            Collections.synchronizedMap(new LinkedHashMap<String, Pattern>(MAX_PATTERNS_TO_CACHE + 1, 0.75f, true) {
                public boolean removeEldestEntry(Map.Entry<String, Pattern> eldest) {
                    return size() > MAX_PATTERNS_TO_CACHE;
                }
            });

    public static int matches(String str, String regex) throws SQLException {
        Matcher matcher = getPattern(regex).matcher(str);
        if (matcher.matches()) {
            return matcher.start() + 1;
        } else {
            return 0;
        }
    }

    public static String replace(String str, String regex, String replacement) throws SQLException {
        return getPattern(regex).matcher(str).replaceAll(replacement);
    }

    public static String replace(String str, String regex) throws SQLException {
        return replace(str, regex, "");
    }

    private static Pattern getPattern(String regex) throws SQLException {
        Pattern p = patternCache.get(regex);
        if (p == null) {
            try {
                p = Pattern.compile(regex);
            } catch (PatternSyntaxException e) {
                throw new SQLException("Pattern syntax error: " + e.getMessage(), "10609", -16068);
            }
            patternCache.put(regex, p);
        }
        return p;
    }
}
