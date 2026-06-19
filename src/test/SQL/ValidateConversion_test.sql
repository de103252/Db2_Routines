-- =====================================================================
-- TEST SUITE FOR VALIDATE CONVERSION FUNCTION
-- =====================================================================
-- Tests for the validate_conversion() function that tests if strings
-- can be converted to specified data types.
--
-- Test Coverage:
-- - Integer type conversions (INTEGER, SMALLINT, BIGINT)
-- - Leading/trailing blanks handling
-- - Invalid input handling
-- - Range validation (overflow detection)
-- - Date conversions with various formats
-- - Leap year validation
-- - DECIMAL with precision and scale
-- - DECFLOAT conversions
-- - TIMESTAMP with timezone
-- - NULL input handling
-- - Invalid type name error handling
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

-----------------------------------------------------------------------
-- Test 1: Comprehensive conversion validation matrix
-----------------------------------------------------------------------

with
d(d) as (
  select 1 from sysibm.sysdummyu
),
tests(value, type, expected_result) as (
            select '42',         'integer',       1 from d 
  union all select '42',         'smallint',      1 from d 
  union all select '42',         'bigint',        1 from d 
  union all select '42',         'smallint',      1 from d 
  union all select '  42  ',     'smallint',      1 from d  -- leading and trailing blanks ok
  union all select 'junk',       'integer',       0 from d  -- complete junk not ok
  union all select '2147483647', 'integer',       1 from d  -- within range 
  union all select '2147483648', 'integer',       0 from d  -- not within range
  union all select '-2147483648', 'integer',      0 from d  -- within range
  union all select '2024-01-09', 'date',          1 from d 
  union all select '1.9.2024',   'date',          1 from d 
  union all select '2024-02-30', 'date',          0 from d  -- No February 30 
  union all select '29.2.2024',  'date',          1 from d  -- Leap year, European date format 
  union all select '29.2.2023',  'date',          0 from d  -- Not a leap year
  union all select '47.11',      'decimal(4, 2)', 1 from d  -- Precision and scale ok
  union all select '-47.11',     'decimal(4, 2)', 1 from d  -- Negative ok
  union all select '47.11',      'decimal(3, 2)', 0 from d  -- Insufficient precision 
  union all select '47.11',      'decimal(3, 1)', 1 from d  -- With truncation of scale, precision now ok 
  union all select '2024.98765', 'decfloat',      1 from d 
  union all select '2024-01-25 16:15:14.12345+01:00',
                   'timestamp(0) with timezone',  1 from d
  union all select cast(null as char), 'integer', 1 from d  -- Nulls ok                                  
),
results as (
  select row_number() over() as row
       , tests.*
       , validate_conversion(value, type) actual_result
    from tests
)
select *
  from results
 where expected_result <> actual_result
    OR 1 = 1 -- remove to see wrong results only
#

-----------------------------------------------------------------------
-- Test 2: Invalid type name error handling
-----------------------------------------------------------------------

-- This is going to fail  
select validate_conversion(cast(null as char), 'bullshit') as result
  from sysibm.sysdummyu#

-- Made with Bob
