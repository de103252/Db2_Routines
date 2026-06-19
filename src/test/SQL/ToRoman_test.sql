-- =====================================================================
-- TEST SUITE FOR ROMAN NUMERAL CONVERSION FUNCTION
-- =====================================================================
-- Tests for the to_roman() function that converts integers to
-- Roman numeral representation.
--
-- Test Coverage:
-- - Current year conversion
-- - Specific year conversions (1964, 9999)
-- - Range of years (current year to current year + 99)
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

-----------------------------------------------------------------------
-- Test 1: Current year conversion
-----------------------------------------------------------------------

select to_roman(year(current date)) as current_year_roman
  from sysibm.sysdummyu
#  

-----------------------------------------------------------------------
-- Test 2: Specific year conversions
-----------------------------------------------------------------------

select to_roman(1964) from sysibm.sysdummyu#
select to_roman(9999) from sysibm.sysdummyu#

-----------------------------------------------------------------------
-- Test 3: Range of years (current to current + 99)
-----------------------------------------------------------------------

--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

select value           as "Year"
     , to_roman(value) as "In saecula saeculorum"
  from table(generate_series(year(current date), 
                             year(current date) + 99))
;

-- Made with Bob
