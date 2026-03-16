-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

-----------------------------------------------------------------------
-- PARSE_URL
-----------------------------------------------------------------------
-- Parses a URL into its component parts and returns them as a table.
--
-- Components returned:
--   scheme    - Protocol (http, https, ftp, etc.)
--   userinfo  - Username and password (if present)
--   host      - Hostname or IP address
--   port      - Port number (if specified)
--   path      - Path component
--   query     - Query string (without ?)
--   fragment  - Fragment identifier (without #)
--
-- URL Format: scheme://[userinfo@]host[:port][/path][?query][#fragment]
--
-- Examples:
--   https://user:pass@example.com:8080/path/to/page?q=1&x=2#section
--   http://example.com/page
--   ftp://ftp.example.com:21/files/
-----------------------------------------------------------------------

DROP FUNCTION SYSFUN.PARSE_URL(url VARCHAR(2048))#

CREATE FUNCTION SYSFUN.PARSE_URL(url VARCHAR(2048))
RETURNS TABLE(component VARCHAR(20), value VARCHAR(2048))
LANGUAGE SQL
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
RETURN
WITH
-- Input validation and normalization
input(url) AS (
  SELECT TRIM(url) FROM SYSIBM.SYSDUMMYU
  WHERE url IS NOT NULL AND url <> ''
),
-- Extract scheme (everything before ://)
scheme_split AS (
  SELECT 
    CASE 
      WHEN LOCATE('://', url) > 0 
      THEN SUBSTR(url, 1, LOCATE('://', url) - 1)
      ELSE NULL
    END AS scheme,
    CASE 
      WHEN LOCATE('://', url) > 0 
      THEN SUBSTR(url, LOCATE('://', url) + 3)
      ELSE url
    END AS remainder
  FROM input
),
-- Extract fragment (everything after #)
fragment_split AS (
  SELECT 
    scheme,
    CASE 
      WHEN LOCATE('#', remainder) > 0 
      THEN SUBSTR(remainder, 1, LOCATE('#', remainder) - 1)
      ELSE remainder
    END AS remainder,
    CASE 
      WHEN LOCATE('#', remainder) > 0 
      THEN SUBSTR(remainder, LOCATE('#', remainder) + 1)
      ELSE NULL
    END AS fragment
  FROM scheme_split
),
-- Extract query string (everything after ?)
query_split AS (
  SELECT 
    scheme,
    fragment,
    CASE 
      WHEN LOCATE('?', remainder) > 0 
      THEN SUBSTR(remainder, 1, LOCATE('?', remainder) - 1)
      ELSE remainder
    END AS remainder,
    CASE 
      WHEN LOCATE('?', remainder) > 0 
      THEN SUBSTR(remainder, LOCATE('?', remainder) + 1)
      ELSE NULL
    END AS query
  FROM fragment_split
),
-- Extract path (everything after first /)
path_split AS (
  SELECT 
    scheme,
    fragment,
    query,
    CASE 
      WHEN LOCATE('/', remainder) > 0 
      THEN SUBSTR(remainder, 1, LOCATE('/', remainder) - 1)
      ELSE remainder
    END AS authority,
    CASE 
      WHEN LOCATE('/', remainder) > 0 
      THEN SUBSTR(remainder, LOCATE('/', remainder))
      ELSE NULL
    END AS path
  FROM query_split
),
-- Extract userinfo (everything before @)
userinfo_split AS (
  SELECT 
    scheme,
    fragment,
    query,
    path,
    CASE 
      WHEN LOCATE('@', authority) > 0 
      THEN SUBSTR(authority, 1, LOCATE('@', authority) - 1)
      ELSE NULL
    END AS userinfo,
    CASE 
      WHEN LOCATE('@', authority) > 0 
      THEN SUBSTR(authority, LOCATE('@', authority) + 1)
      ELSE authority
    END AS host_port
  FROM path_split
),
-- Extract port (everything after last :)
port_split AS (
  SELECT 
    scheme,
    fragment,
    query,
    path,
    userinfo,
    CASE 
      -- Check if there's a colon and it's not part of IPv6 address
      WHEN LOCATE(':', host_port) > 0 
           AND LOCATE('[', host_port) = 0  -- Not IPv6
      THEN SUBSTR(host_port, 1, LOCATE(':', host_port) - 1)
      ELSE host_port
    END AS host,
    CASE 
      WHEN LOCATE(':', host_port) > 0 
           AND LOCATE('[', host_port) = 0  -- Not IPv6
      THEN SUBSTR(host_port, LOCATE(':', host_port) + 1)
      ELSE NULL
    END AS port
  FROM userinfo_split
),
-- Extract username and password from userinfo
credentials_split AS (
  SELECT 
    scheme,
    fragment,
    query,
    path,
    host,
    port,
    CASE 
      WHEN userinfo IS NOT NULL AND LOCATE(':', userinfo) > 0 
      THEN SUBSTR(userinfo, 1, LOCATE(':', userinfo) - 1)
      ELSE userinfo
    END AS username,
    CASE 
      WHEN userinfo IS NOT NULL AND LOCATE(':', userinfo) > 0 
      THEN SUBSTR(userinfo, LOCATE(':', userinfo) + 1)
      ELSE NULL
    END AS password
  FROM port_split
),
-- Assemble all components
components AS (
  SELECT 'scheme'   AS component, scheme   AS value FROM credentials_split WHERE scheme   IS NOT NULL
  UNION ALL
  SELECT 'username' AS component, username AS value FROM credentials_split WHERE username IS NOT NULL
  UNION ALL
  SELECT 'password' AS component, password AS value FROM credentials_split WHERE password IS NOT NULL
  UNION ALL
  SELECT 'host'     AS component, host     AS value FROM credentials_split WHERE host     IS NOT NULL
  UNION ALL
  SELECT 'port'     AS component, port     AS value FROM credentials_split WHERE port     IS NOT NULL
  UNION ALL
  SELECT 'path'     AS component, path     AS value FROM credentials_split WHERE path     IS NOT NULL
  UNION ALL
  SELECT 'query'    AS component, query    AS value FROM credentials_split WHERE query    IS NOT NULL
  UNION ALL
  SELECT 'fragment' AS component, fragment AS value FROM credentials_split WHERE fragment IS NOT NULL
)
SELECT component, value FROM components
#

-----------------------------------------------------------------------
-- Helper function: GET_URL_COMPONENT
-- Returns a specific component from a URL
-----------------------------------------------------------------------

DROP FUNCTION SYSFUN.GET_URL_COMPONENT(url VARCHAR(2048), 
                                       component_name VARCHAR(20))#

CREATE FUNCTION SYSFUN.GET_URL_COMPONENT(url VARCHAR(2048), 
                                         component_name VARCHAR(20))
RETURNS VARCHAR(2048)
LANGUAGE SQL
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
RETURN
  SELECT value 
    FROM TABLE(SYSFUN.PARSE_URL(url))
   WHERE component = component_name
   FETCH FIRST 1 ROW ONLY
#

-----------------------------------------------------------------------
-- Test Cases
-----------------------------------------------------------------------

-- Test 1: Complete URL with all components
SELECT * 
  FROM TABLE(SYSFUN.PARSE_URL(
    'https://user:pass@example.com:8080/path/to/page?q=1&x=2#section'))
 ORDER BY component
#

-- Expected results:
-- COMPONENT  VALUE
-- fragment   section
-- host       example.com
-- password   pass
-- path       /path/to/page
-- port       8080
-- query      q=1&x=2
-- scheme     https
-- username   user

-- Test 2: Simple HTTP URL
SELECT * 
  FROM TABLE(SYSFUN.PARSE_URL('http://example.com/page'))
 ORDER BY component
#

-- Test 3: URL with query string only
SELECT * 
  FROM TABLE(SYSFUN.PARSE_URL('https://api.example.com/search?q=db2&limit=10'))
 ORDER BY component
#

-- Test 4: FTP URL with port
SELECT * 
  FROM TABLE(SYSFUN.PARSE_URL('ftp://ftp.example.com:21/files/'))
 ORDER BY component
#

-- Test 5: URL with fragment only
SELECT * 
  FROM TABLE(SYSFUN.PARSE_URL('https://docs.example.com/manual#chapter5'))
 ORDER BY component
#

-- Test 6: Localhost with port
SELECT * 
  FROM TABLE(SYSFUN.PARSE_URL('http://localhost:8080/admin'))
 ORDER BY component
#

-- Test 7: Using GET_URL_COMPONENT helper
SELECT 
  SYSFUN.GET_URL_COMPONENT('https://example.com:443/api/v1?key=abc', 'scheme') AS scheme,
  SYSFUN.GET_URL_COMPONENT('https://example.com:443/api/v1?key=abc', 'host') AS host,
  SYSFUN.GET_URL_COMPONENT('https://example.com:443/api/v1?key=abc', 'port') AS port,
  SYSFUN.GET_URL_COMPONENT('https://example.com:443/api/v1?key=abc', 'path') AS path,
  SYSFUN.GET_URL_COMPONENT('https://example.com:443/api/v1?key=abc', 'query') AS query
FROM SYSIBM.SYSDUMMYU
#

-- Test 8: Extract host from multiple URLs
WITH urls(url) AS (
  VALUES 
    ('https://www.ibm.com/products/db2'),
    ('http://github.com/user/repo'),
    ('ftp://files.example.org/downloads/')
)
SELECT 
  url,
  SYSFUN.GET_URL_COMPONENT(url, 'scheme') AS scheme,
  SYSFUN.GET_URL_COMPONENT(url, 'host') AS host,
  SYSFUN.GET_URL_COMPONENT(url, 'path') AS path
FROM urls
#

-- Test 9: Parse API endpoint URLs
WITH api_calls(endpoint) AS (
  VALUES 
    ('https://api.example.com/v1/users?limit=10&offset=0'),
    ('https://api.example.com/v1/orders/12345'),
    ('https://api.example.com/v2/products?category=electronics&sort=price')
)
SELECT 
  endpoint,
  SYSFUN.GET_URL_COMPONENT(endpoint, 'path') AS api_path,
  SYSFUN.GET_URL_COMPONENT(endpoint, 'query') AS query_params
FROM api_calls
#

-- Test 10: Validate URL structure
WITH test_urls(url, expected_host) AS (
  VALUES 
    ('https://example.com/page', 'example.com'),
    ('http://test.example.com:8080/', 'test.example.com'),
    ('ftp://ftp.example.org/files', 'ftp.example.org')
)
SELECT 
  url,
  expected_host,
  SYSFUN.GET_URL_COMPONENT(url, 'host') AS actual_host,
  CASE 
    WHEN SYSFUN.GET_URL_COMPONENT(url, 'host') = expected_host 
    THEN 'PASS' 
    ELSE 'FAIL' 
  END AS test_result
FROM test_urls
#

-- Test 11: Extract query parameters (requires additional parsing)
-- This shows how to further parse the query string
WITH url_data AS (
  SELECT SYSFUN.GET_URL_COMPONENT(
    'https://example.com/search?q=db2&category=database&limit=10', 
    'query') AS query_string
  FROM SYSIBM.SYSDUMMYU
)
SELECT query_string,
       -- Note: Further parsing of query string into key-value pairs
       -- would require additional functions or REGEX_REPLACE
       LENGTH(query_string) AS query_length,
       CASE WHEN query_string LIKE '%q=%' THEN 'Has q parameter' END AS has_q
FROM url_data
#

-- Test 12: Handle edge cases
SELECT 'No scheme' AS test_case, component, value
  FROM TABLE(SYSFUN.PARSE_URL('example.com/page'))
UNION ALL
SELECT 'Empty URL' AS test_case, component, value
  FROM TABLE(SYSFUN.PARSE_URL(''))
UNION ALL
SELECT 'NULL URL' AS test_case, component, value
  FROM TABLE(SYSFUN.PARSE_URL(CAST(NULL AS VARCHAR(2048))))
#

-- Following comment lines tell Data Studio resp. SPUFI
-- to use ; as statement terminator
--
--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

-- Made with Bob
