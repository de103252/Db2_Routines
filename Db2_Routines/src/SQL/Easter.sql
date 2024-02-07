-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

-- drop function easter(year integer)#

-- Returns the date of Easter Sunday in the given year, which must be
-- a year after the Gregorian calendar reform (>= 1583).
create function easter(year integer)
  returns date
  language sql
  deterministic
begin
  declare a, b, c, d, e, f, g, h, i, k, l, m integer;
  declare n, o decimal(2);

  if year <= 1582 then
    signal sqlstate '70815' 
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

select current date as today, easter(year(current date)) as easter
  from sysibm.sysdummyu
#

select easter(value) as "Easter Sunday"
  from table(generate_series(2000, 2050))
#

select easter(1582) from sysibm.sysdummyu
#

