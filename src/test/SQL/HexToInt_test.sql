-- =====================================================================
-- TEST SUITE FOR HEXADECIMAL TO INTEGER CONVERSION FUNCTION
-- =====================================================================
-- Tests for the hextoint() function that converts hexadecimal strings
-- to integer values.
--
-- Test Coverage:
-- - Basic hex conversions (0, 42, 7FFFFFFF, 80000000)
-- - Large hex value (DEADBEEF)
-- - Error handling for invalid hex string
-- - NULL input handling
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

-----------------------------------------------------------------------
-- Test 1: Basic hex conversions with expected results
-----------------------------------------------------------------------

with
d(d) as (
  select 1 from sysibm.sysdummyu
),
tests(hexstr, expected_result) as (
            select '0',        0 from d 
  union all select '42',       66 from d
  union all select '7fffffff', 2147483647 from d
  union all select '80000000', 2147483648 from d
),
results as (
  select row_number() over() as row
       , tests.*
       , hextoint(hexstr) actual_result
    from tests
)
select *
  from results
 where expected_result <> actual_result OR 1 = 1
#

-----------------------------------------------------------------------
-- Test 2: Large hex value
-----------------------------------------------------------------------

select hextoint('DEADBEEF') as result from sysibm.sysdummyu;

-----------------------------------------------------------------------
-- Test 3: Error handling - invalid hex string
-----------------------------------------------------------------------

select hextoint('JUNK!!!') as result from sysibm.sysdummyu;

-----------------------------------------------------------------------
-- Test 4: NULL input handling
-----------------------------------------------------------------------

select hextoint(cast(null as char)) as result from sysibm.sysdummyu;

-- Made with Bob
