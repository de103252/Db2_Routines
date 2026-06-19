-- =====================================================================
-- ROMAN NUMERAL CONVERSION FUNCTION
-- =====================================================================
-- Convert integer to Roman numeral representation.
--
-- Features:
-- - Converts integers to Roman numeral strings
-- - Supports range 1 to 9999
-- - Uses standard Roman numeral notation (I, V, X, L, C, D, M)
-- - Deterministic with no external actions
-- - Returns NULL on NULL input
--
-- Roman Numeral Rules:
-- - I=1, V=5, X=10, L=50, C=100, D=500, M=1000
-- - Subtractive notation: IV=4, IX=9, XL=40, XC=90, CD=400, CM=900
--
-- Usage Examples:
-- - Convert 42: SELECT to_roman(42) FROM SYSIBM.SYSDUMMYU  -- Returns 'XLII'
-- - Convert 2024: SELECT to_roman(2024) FROM SYSIBM.SYSDUMMYU  -- Returns 'MMXXIV'
-- - Convert 1: SELECT to_roman(1) FROM SYSIBM.SYSDUMMYU  -- Returns 'I'
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

drop function to_roman(number smallint)#
create function to_roman(number smallint)
returns varchar(20)
returns null on null input
  deterministic
  no external action
begin
  declare roman varchar(20) default '';
 
  -- Check allowed range
  if number not between 1 and 9999 then
    signal sqlstate '77753' set message_text =
      'Can only convert positive integers up to 9999 to Roman numerals';
  end if;
  
  while number > 0 do 
    with
    u as (select * from sysibm.sysdummyu),
    n(d, r) as (
      select 1000, 'M'  from u union all
      select  900, 'CM' from u union all
      select  500, 'D'  from u union all
      select  400, 'CD' from u union all
      select  100, 'C'  from u union all
      select   90, 'XC' from u union all
      select   50, 'L'  from u union all
      select   40, 'XL' from u union all
      select   10, 'X'  from u union all
      select    9, 'IX' from u union all
      select    5, 'V'  from u union all
      select    4, 'IV' from u union all
      select    1, 'I'  from u 
    )
    select number - d, concat(roman, r)
      into number, roman 
      from n
     where number >= d
     order by d desc
     fetch first row only;
  end while;
  return roman;
end
#
