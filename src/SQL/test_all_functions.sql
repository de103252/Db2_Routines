-- =====================================================================
-- TEST SUITE FOR ALL USER-DEFINED FUNCTIONS
-- =====================================================================
-- This file systematically tests all UDFs in the Db2_Routines project
-- to verify successful deployment and functionality.
--
-- Execute this file after deploying all functions to validate the
-- database environment is properly configured.
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

-- =====================================================================
-- SECTION 1: STRING MANIPULATION FUNCTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1.1 BASE64 ENCODING/DECODING
-- ---------------------------------------------------------------------
-- Test base64encode with BLOB input
select 'BASE64 ENCODE (BLOB)' as test_category
     , base64encode(cast('Hello, Db2 for z/OS!' as blob)) as result
  from sysibm.sysdummyu
#

-- Test base64encode with VARBINARY input
select 'BASE64 ENCODE (VARBINARY)' as test_category
     , base64encode(varbinary('Test Data')) as result
  from sysibm.sysdummyu
#

-- Test base64decode with CLOB input
select 'BASE64 DECODE (CLOB)' as test_category
     , base64decode(clob('SGVsbG8sIERiMiBmb3Igei9PUyE=')) as result
  from sysibm.sysdummyu
#

-- Test base64decode with VARCHAR input
select 'BASE64 DECODE (VARCHAR)' as test_category
     , base64decode('VGVzdCBEYXRh') as result
  from sysibm.sysdummyu
#

-- Test base64 round-trip
select 'BASE64 ROUND-TRIP' as test_category
     , case when base64decode(base64encode(cast('Round Trip Test' as varbinary(256)))) 
               = cast('Round Trip Test' as varbinary(256))
            then 'PASS' 
            else 'FAIL' 
       end as result
  from sysibm.sysdummyu
#

-- ---------------------------------------------------------------------
-- 1.2 REGULAR EXPRESSION FUNCTIONS
-- ---------------------------------------------------------------------
-- Test regex_matches
select 'REGEX MATCHES' as test_category
     , regex_matches('test@example.com', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') as result
  from sysibm.sysdummyu
#

-- Test regex_replace (2 parameters)
select 'REGEX REPLACE (2 PARAMS)' as test_category
     , regex_replace('Hello World 123', '\d+') as result
  from sysibm.sysdummyu
#

-- Test regex_replace (3 parameters)
select 'REGEX REPLACE (3 PARAMS)' as test_category
     , regex_replace('Hello World', '(?i)world', 'Db2') as result
  from sysibm.sysdummyu
#

-- Test regex_replace - remove duplicate words
select 'REGEX REMOVE DUPLICATES' as test_category
     , regex_replace('This is a very very very simple example',
                     '\b(\w+)(?:\W+\1\b)+',
                     '$1') as result
  from sysibm.sysdummyu
#

-- ---------------------------------------------------------------------
-- 1.3 STRING SPLITTING FUNCTIONS
-- ---------------------------------------------------------------------
-- Test split function with comma delimiter
select 'SPLIT FUNCTION' as test_category
     , seqno
     , token
  from table(sysfun.split('apple,banana,cherry,date'))
 order by seqno
 fetch first 4 rows only
#

-- Test split with regex delimiter
select 'SPLIT WITH REGEX' as test_category
     , seqno
     , token
  from table(sysfun.split('one:two;three#four', '[:;#]'))
 order by seqno
 fetch first 4 rows only
#

-- =====================================================================
-- SECTION 2: DATE AND TIME FUNCTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2.1 EASTER CALCULATION
-- ---------------------------------------------------------------------
-- Test easter function for current year
select 'EASTER CURRENT YEAR' as test_category
     , sysfun.easter(year(current date)) as result
  from sysibm.sysdummyu
#

-- Test easter function for specific years
with years(year) as (
  select value from table(generate_series(year(current date) - 10, year(current date) + 10))
)
select 'EASTER SPECIFIC YEARS' as test_category
     , year
     , sysfun.easter(year) as easter_date
  from years
#

-- ---------------------------------------------------------------------
-- 2.2 TIMESTAMP FORMATTING
-- ---------------------------------------------------------------------
-- Test formattimestamp with default locale
select 'FORMAT TIMESTAMP (DEFAULT)' as test_category
     , formattimestamp(current timestamp, 'EEEE, d MMMM yyyy HH:mm:ss') as result
  from sysibm.sysdummyu
#

-- Test formattimestamp with specific locale
select 'FORMAT TIMESTAMP (LOCALE)' as test_category
     , formattimestamp(current timestamp, 'EEEE, d MMMM yyyy HH:mm:ss', 'de-DE') as result
  from sysibm.sysdummyu
#

-- Test formattimestamp with multiple locales
with locales(locale) as (
  select 'en-US' from sysibm.sysdummyu union all
  select 'de-DE' from sysibm.sysdummyu union all
  select 'fr-FR' from sysibm.sysdummyu union all
  select 'ja-JP' from sysibm.sysdummyu
)
select 'FORMAT TIMESTAMP (MULTI-LOCALE)' as test_category
     , locale
     , formattimestamp(timestamp('2025-12-25-12:00:00'), 'EEEE, d MMMM yyyy', locale) as result
  from locales
#

-- =====================================================================
-- SECTION 3: NUMERIC FUNCTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 3.1 NUMBER CONVERSION FUNCTIONS
-- ---------------------------------------------------------------------
-- Test hextoint function
select 'HEX TO INT' as test_category
     , sysfun.hextoint('DEADBEEF') as result
  from sysibm.sysdummyu
#

-- Test hextoint with various inputs
with test_data(hex_value) as (
  select '0' from sysibm.sysdummyu union all
  select '42' from sysibm.sysdummyu union all
  select 'FF' from sysibm.sysdummyu union all
  select '7FFFFFFF' from sysibm.sysdummyu union all
  select '80000000' from sysibm.sysdummyu
)
select 'HEX TO INT (VARIOUS)' as test_category
     , hex_value
     , sysfun.hextoint(hex_value) as decimal_value
  from test_data
#

-- Test to_roman function
select 'TO ROMAN' as test_category
     , to_roman(year(current date)) as result
  from sysibm.sysdummyu
#

-- Test to_roman with various numbers
with test_data(number) as (
  select 1 from sysibm.sysdummyu union all
  select 4 from sysibm.sysdummyu union all
  select 9 from sysibm.sysdummyu union all
  select 42 from sysibm.sysdummyu union all
  select 1964 from sysibm.sysdummyu union all
  select 2024 from sysibm.sysdummyu union all
  select 9999 from sysibm.sysdummyu
)
select 'TO ROMAN (VARIOUS)' as test_category
     , number
     , to_roman(number) as roman_numeral
  from test_data
#

-- ---------------------------------------------------------------------
-- 3.2 TRY CONVERSION FUNCTIONS
-- ---------------------------------------------------------------------
-- Test try_integer
with test_data(input_value) as (
  select '42' from sysibm.sysdummyu union all
  select '  123  ' from sysibm.sysdummyu union all
  select 'invalid' from sysibm.sysdummyu union all
  select cast(null as varchar(10)) from sysibm.sysdummyu
)
select 'TRY INTEGER' as test_category
     , input_value
     , sysfun.try_integer(input_value) as result
  from test_data
#

-- Test try_smallint
with test_data(input_value) as (
  select '42' from sysibm.sysdummyu union all
  select '32767' from sysibm.sysdummyu union all
  select '99999' from sysibm.sysdummyu union all
  select 'abc' from sysibm.sysdummyu
)
select 'TRY SMALLINT' as test_category
     , input_value
     , sysfun.try_smallint(input_value) as result
  from test_data
#

-- Test try_bigint
with test_data(input_value) as (
  select '42' from sysibm.sysdummyu union all
  select '9223372036854775807' from sysibm.sysdummyu union all
  select 'invalid' from sysibm.sysdummyu
)
select 'TRY BIGINT' as test_category
     , input_value
     , sysfun.try_bigint(input_value) as result
  from test_data
#

-- =====================================================================
-- SECTION 4: VALIDATION FUNCTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 4.1 VALIDATE CONVERSION
-- ---------------------------------------------------------------------
-- Test validate_conversion with integers
with test_data(value) as (
  select '42' from sysibm.sysdummyu union all
  select '2147483647' from sysibm.sysdummyu union all
  select '2147483648' from sysibm.sysdummyu union all
  select 'abc' from sysibm.sysdummyu
)
select 'VALIDATE CONVERSION (INT)' as test_category
     , value
     , sysfun.validate_conversion(value, 'integer') as is_valid
  from test_data
#

-- Test validate_conversion with dates
with test_data(value) as (
  select '2024-01-09' from sysibm.sysdummyu union all
  select '2024-02-30' from sysibm.sysdummyu union all
  select '29.2.2024' from sysibm.sysdummyu union all
  select 'invalid' from sysibm.sysdummyu
)
select 'VALIDATE CONVERSION (DATE)' as test_category
     , value
     , sysfun.validate_conversion(value, 'date') as is_valid
  from test_data
#

-- Test validate_conversion with decimals
with test_data(value) as (
  select '123.45' from sysibm.sysdummyu union all
  select '12345.67' from sysibm.sysdummyu union all
  select '-99.99' from sysibm.sysdummyu union all
  select 'abc' from sysibm.sysdummyu
)
select 'VALIDATE CONVERSION (DECIMAL)' as test_category
     , value
     , sysfun.validate_conversion(value, 'decimal(5,2)') as is_valid
  from test_data
#

-- ---------------------------------------------------------------------
-- 4.2 VALIDATE EAN
-- ---------------------------------------------------------------------
-- Test validate_ean with valid and invalid codes
with test_data(ean) as (
  select 4003994155485 from sysibm.sysdummyu union all
  select 9783966451192 from sysibm.sysdummyu union all
  select 4015532205577 from sysibm.sysdummyu union all
  select 1234567890123 from sysibm.sysdummyu
)
select 'VALIDATE EAN' as test_category
     , ean
     , case validate_ean(ean)
            when 1 then 'VALID'
            else 'INVALID'
       end as result
  from test_data
#

-- =====================================================================
-- SECTION 5: TABLE FUNCTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 5.1 GENERATE SERIES
-- ---------------------------------------------------------------------
-- Test generate_series with 2 parameters
select 'GENERATE SERIES (2 PARAMS)' as test_category
     , value
  from table(sysfun.generate_series(1, 10))
 order by value
#

-- Test generate_series with 3 parameters (step)
select 'GENERATE SERIES (3 PARAMS)' as test_category
     , value
  from table(sysfun.generate_series(0, 20, 5))
 order by value
#

-- Test generate_series with negative step
select 'GENERATE SERIES (COUNTDOWN)' as test_category
     , value as countdown
  from table(sysfun.generate_series(10, 1, -1))
 order by value desc
#

-- =====================================================================
-- SECTION 6: FORMATTING FUNCTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 6.1 SPRINTF FUNCTION
-- ---------------------------------------------------------------------
-- Test sprintf with packed data
select 'SPRINTF (BASIC)' as test_category
     , sprintf('%s: %d', pack(ccsid 1208, 'Answer', 42)) as result
  from sysibm.sysdummyu
#

-- Test sprintf with locale
select 'SPRINTF (LOCALE)' as test_category
     , sprintf('de-DE', '%,d', pack(ccsid 1208, 1234567)) as result
  from sysibm.sysdummyu
#

-- Test sprintf with timestamp
select 'SPRINTF (TIMESTAMP)' as test_category
     , sprintf('en-US', '%1$tB %1$te, %1$tY', pack(ccsid 1208, current timestamp)) as result
  from sysibm.sysdummyu
#

-- Test sprintf with multiple locales
with locales(locale) as (
  select 'en-US' from sysibm.sysdummyu union all
  select 'de-DE' from sysibm.sysdummyu union all
  select 'fr-FR' from sysibm.sysdummyu union all
  select 'es-ES' from sysibm.sysdummyu union all
  select 'ja-JP' from sysibm.sysdummyu
)
select 'SPRINTF (MULTI-LOCALE)' as test_category
     , locale
     , sprintf(locale, '%1$tB', pack(ccsid 1208, current timestamp)) as month_name
  from locales
#

-- =====================================================================
-- SECTION 7: FILE EXPORT FUNCTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 7.1 UNLOADCSV
-- ---------------------------------------------------------------------
-- Test UNLOADCSV default signature
select 'UNLOADCSV (DEFAULT SIGNATURE)' as test_category
     , unloadcsv(
           'select empno, lastname, workdept from dsn81310.emp fetch first 3 rows only',
           '/tmp/unloadcsv_emp_default.csv') as rows_unloaded
  from sysibm.sysdummyu
#

-- Test UNLOADCSV extended signature with predefined format and header
select 'UNLOADCSV (PREDEFINED FORMAT)' as test_category
     , unloadcsv(
           'select empno, lastname, workdept from dsn81310.emp fetch first 3 rows only',
           '/tmp/unloadcsv_emp_excel.csv',
           'Excel',
           1208,
           'Y') as rows_unloaded
  from sysibm.sysdummyu
#

-- Test UNLOADCSV extended signature with custom format
select 'UNLOADCSV (CUSTOM FORMAT)' as test_category
     , unloadcsv(
           'select empno, lastname, workdept from dsn81310.emp fetch first 3 rows only',
           '/tmp/unloadcsv_emp_pipe.txt',
           'delimiter=\|;quoteMode=MINIMAL;nullString=(null);trim=true',
           1208,
           'Y') as rows_unloaded
  from sysibm.sysdummyu
#

-- Test UNLOADCSV with multiple predefined formats
with predef_formats(format_name) as (
  select 'Default' from sysibm.sysdummyu union all
  select 'Excel' from sysibm.sysdummyu union all
  select 'RFC4180' from sysibm.sysdummyu union all
  select 'TDF' from sysibm.sysdummyu
)
select 'UNLOADCSV (MULTI-FORMAT)' as test_category
     , format_name
     , unloadcsv(
           'select empno, lastname from dsn81310.emp fetch first 2 rows only',
           '/tmp/unloadcsv_' || lower(format_name) || '.csv',
           format_name,
           1208,
           'Y') as rows_unloaded
  from predef_formats
#

-- Test UNLOADCSV with EBCDIC CCSID target
select 'UNLOADCSV (EBCDIC CCSID)' as test_category
     , unloadcsv(
           'select empno, lastname from dsn81310.emp fetch first 2 rows only',
           '/tmp/unloadcsv_emp_1047.csv',
           'Excel',
           1047,
           'Y') as rows_unloaded
  from sysibm.sysdummyu
#

-- =====================================================================
-- SECTION 8: NULL HANDLING TESTS
-- =====================================================================

-- Test functions with NULL inputs
select 'NULL HANDLING' as test_category
     , 'base64encode' as function_name
     , case when base64encode(cast(null as blob)) is null 
            then 'PASS' else 'FAIL' end as result
  from sysibm.sysdummyu
union all
select 'NULL HANDLING' as test_category
     , 'hextoint' as function_name
     , case when sysfun.hextoint(cast(null as varchar(10))) is null 
            then 'PASS' else 'FAIL' end as result
  from sysibm.sysdummyu
union all
select 'NULL HANDLING' as test_category
     , 'to_roman' as function_name
     , case when to_roman(cast(null as smallint)) is null 
            then 'PASS' else 'FAIL' end as result
  from sysibm.sysdummyu
union all
select 'NULL HANDLING' as test_category
     , 'easter' as function_name
     , case when sysfun.easter(cast(null as integer)) is null 
            then 'PASS' else 'FAIL' end as result
  from sysibm.sysdummyu
union all
select 'NULL HANDLING' as test_category
     , 'try_integer' as function_name
     , case when sysfun.try_integer(cast(null as varchar(10))) is null 
            then 'PASS' else 'FAIL' end as result
  from sysibm.sysdummyu
#

-- =====================================================================
-- SECTION 9: INTEGRATION TESTS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 8.1 COMBINED FUNCTION USAGE
-- ---------------------------------------------------------------------
-- Test combining generate_series with easter
select 'INTEGRATION: SERIES + EASTER' as test_category
     , value as year
     , sysfun.easter(value) as easter_sunday
  from table(sysfun.generate_series(2024, 2030))
 order by value
#

-- Test combining split with validation
select 'INTEGRATION: SPLIT + VALIDATE' as test_category
     , token
     , sysfun.validate_conversion(token, 'integer') as is_integer
  from table(sysfun.split('42,abc,123,xyz,999'))
#

-- Test combining generate_series with to_roman
select 'INTEGRATION: SERIES + ROMAN' as test_category
     , value as number
     , to_roman(value) as roman_numeral
  from table(sysfun.generate_series(1, 20))
 order by value
#

-- =====================================================================
-- SECTION 10: PERFORMANCE AND EDGE CASES
-- =====================================================================

-- Test with empty strings
select 'EDGE CASE: EMPTY STRING' as test_category
     , 'base64encode' as function_name
     , length(base64encode(cast('' as blob))) as result_length
  from sysibm.sysdummyu
#

-- Test with maximum values
select 'EDGE CASE: MAX VALUES' as test_category
     , 'to_roman' as function_name
     , to_roman(9999) as result
  from sysibm.sysdummyu
#

-- Test with minimum values
select 'EDGE CASE: MIN VALUES' as test_category
     , 'to_roman' as function_name
     , to_roman(1) as result
  from sysibm.sysdummyu
#

-- =====================================================================
-- END OF TEST SUITE
-- =====================================================================
-- All tests completed. Review results for any failures or errors.
-- Expected behavior:
-- - All functions should return results without SQL errors
-- - NULL handling tests should all show 'PASS'
-- - Integration tests should demonstrate proper function composition
-- =====================================================================
