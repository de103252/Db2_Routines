-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

/*
Convert a hex string to an integer (inverse of HEX function).
The string must contain upper- or lower-case hex digits only
(0..9, A..F, a..f). otherwise, SQLSTATE 72606 is raised.
The hex string must represent a number within the range of an
INTEGER, otherwise, an overflow condition is raised (SQLSTATE 22003).
*/

drop function sysfun.hextoint(s varchar(32704))#

create function sysfun.hextoint(s varchar(32704))
  returns bigint
  deterministic
  parameter ccsid unicode
  no external action
begin
  declare value bigint default 0;
  set s = upper(s);
  if length(s) = 0 then
    signal sqlstate '72606' 
       set message_text ='INVALID HEXADECIMAL CONSTANT'; 
  end if;
  while length(s) > 0 do
    set value = 16*value 
              + case when ascii(s) between ascii('0') and ascii('9')
                     then ascii(s) - ascii('0')
                     when ascii(s) between ascii('A') and ascii('F')
                     then ascii(s) - ascii('A') + 10
                     else raise_error('72606', 
                                      'INVALID HEXADECIMAL CONSTANT')
                end;
    if length(s) > 1 then
      set s = substr(s, 2);
    else 
      set s = ''; 
    end if;
  end while;
  return value;
end
#

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
 where expected_result <> actual_result
#

select cast(-2147483649 as integer) from sysibm.sysdummyu;
