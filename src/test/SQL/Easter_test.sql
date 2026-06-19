-- =====================================================================
-- TEST SUITE FOR EASTER DATE CALCULATION FUNCTION
-- =====================================================================
-- Tests for the easter() function that calculates Easter Sunday dates
-- using the Meeus/Jones/Butcher Gregorian algorithm.
--
-- Test Coverage:
-- - Current year Easter calculation
-- - Range of years (2000-2050)
-- - Error handling for pre-Gregorian calendar years
-- - NULL input handling
-- - Integration with other functions (generate_series, to_roman, formattimestamp)
-- =====================================================================

--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

-----------------------------------------------------------------------
-- Test 1: Easter for current year
-----------------------------------------------------------------------

-- When was Easter this year?
select easter(year(current date)) as easter
  from sysibm.sysdummyu
;

-----------------------------------------------------------------------
-- Test 2: Easter Sundays range (2000-2050)
-----------------------------------------------------------------------

-- Show Easter Sundays between 2000 and 2050.
-- This uses the generate_series function defined next door.
select easter(value) as "Easter Sunday"
  from table(generate_series(2000, 2050))
;

-----------------------------------------------------------------------
-- Test 3: Error handling - pre-Gregorian calendar year
-----------------------------------------------------------------------

-- Years before 1583 not allowed, will raise an SQL error.
select easter(1582) 
  from sysibm.sysdummyu
;

-----------------------------------------------------------------------
-- Test 4: NULL input handling
-----------------------------------------------------------------------

select easter(cast(null as integer))
  from sysibm.sysdummyu
;

-----------------------------------------------------------------------
-- Test 5: Integration with formatting functions
-----------------------------------------------------------------------

with
jahre as (
  select value as jahr
       , timestamp(easter(value)) as Ostern
    from table(generate_series(year(current date), year(current date) + 100))
)
select to_roman(jahr) as "Jahr"
     , formattimestamp(ostern,           'long', 'de-DE') as "Ostern"
     , formattimestamp(ostern + 39 days, 'd. MMMM', 'fr-CH') as "Ascension"
     , formattimestamp(ostern + 49 days, 'd. MMMM', 'it-CH') as "Pentecoste"
     , formattimestamp(ostern + 60 days, 'd. MMMM', 'rm-CH') as "Corpus Christi"
  from jahre
;

-- Made with Bob
