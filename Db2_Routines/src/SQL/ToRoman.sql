-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

------------------------------------------------------------------------
-- This extremely useful UDF converts a small integer
-- to a roman numeral.
-- Only values in the range [1..9999] are allowed.
------------------------------------------------------------------------
drop function to_roman(number smallint)#
create function to_roman(number smallint)
returns varchar(20)
  deterministic
  no external action
begin
  declare roman varchar(20) default '';
 
  if number not between 1 and 3999 then
    signal sqlstate '76543' set message_text =
      'Can only convert positive integers up to 3999 to Roman numerals';
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

--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

select to_roman(year(current date)) as current_year_roman
  from sysibm.sysdummyu;
  
select to_roman(1964) from sysibm.sysdummyu;
