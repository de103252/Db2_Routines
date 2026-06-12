-- =====================================================================
-- EASTER DATE CALCULATION FUNCTION
-- =====================================================================
-- Calculate the date of Easter Sunday for any given year.
--
-- Features:
-- - Uses the Meeus/Jones/Butcher Gregorian algorithm
-- - Supports years from 1583 onwards (Gregorian calendar reform)
-- - Returns DATE type for easy date arithmetic
-- - Deterministic function for consistent results
--
-- Algorithm Reference:
-- http://en.wikipedia.org/wiki/Computus#Meeus.2FJones.2FButcher_Gregorian_algorithm
--
-- Usage Examples:
-- - Get Easter 2024: SELECT easter(2024) FROM SYSIBM.SYSDUMMYU
-- - Get Easter for current year: SELECT easter(YEAR(CURRENT DATE)) FROM SYSIBM.SYSDUMMYU
-- - Calculate days until Easter: SELECT easter(2025) - CURRENT DATE FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

-- drop function easter(year integer)#

create function easter(year integer)
  returns date
  language sql
  deterministic
begin
  declare a, b, c, d, e, f, g, h, i, k, l, m integer;
  declare n, o decimal(2);

  if year <= 1582 then
    signal sqlstate '71583' 
      set message_text = 
        'Only years in Gregorian calendar (1583 and later) allowed';
  end if;

  set a = mod(year, 19)
    , b = year / 100 
    , c = mod(year, 100);
  set d = b / 4 
    , e = mod(b, 4) 
    , g = (8*b + 13 ) / 25;
  set h = mod(19*a + b - d - g + 15, 30) 
    , i = c / 4;
  set k = mod(c, 4);
  set l = mod(32 + 2*e + 2*i - h - k, 7);
  set m = (a + 11*h + 19*l) / 433;
  set n = (h + l - 7*m + 90) / 25;
  set o = mod(h + l - 7*m + 33*n + 19, 32);
  return date(digits(decimal(year, 4)) || 
              '-' || digits(n) ||
              '-' || digits(o));
end
#

-----------------------------------------------------------------------
-- Test
-----------------------------------------------------------------------

--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

-- When was Easter this year?
select easter(year(current date)) as easter
  from sysibm.sysdummyu
;

-- Show Easter Sundays between 2000 and 2050.
-- This uses the generate_series function defined next door.
select easter(value) as "Easter Sunday"
  from table(generate_series(2000, 2050))
;

-- Years before 1583 not allowed, will raise an SQL error.
select easter(1582) 
  from sysibm.sysdummyu
;

select easter(cast(null as integer))
  from sysibm.sysdummyu
;

with
jahre as (
  select value as jahr
       , timestamp(easter(value)) as Ostern
    from table(generate_series(year(current date), year(current date) + 10))
)
select to_roman(jahr) as "Jahr"
     , formattimestamp(ostern,           'd. MMMM', 'de-DE') as "Ostern"
     , formattimestamp(ostern + 39 days, 'd. MMMM', 'de-DE') as "Himmelfahrt"
     , formattimestamp(ostern + 49 days, 'd. MMMM', 'de-DE') as "Pfingsten"
     , formattimestamp(ostern + 60 days, 'd. MMMM', 'de-DE') as "Fronleichnam"
  from jahre
;