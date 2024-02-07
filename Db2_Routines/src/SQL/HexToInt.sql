-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

drop function sysfun.hextoint(s varchar(32704))
#

create function sysfun.hextoint(s varchar(32704))
  returns integer
  deterministic
  parameter ccsid unicode
  no external action
begin
  declare value bigint default 0;
  set s = upper(trim(s));
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
  if value >= 2147483648 then
    return 2147483647 - value;
  else
    return value;
  end if;
end
#

select hextoint('1ffffffff')
from sysibm.sysdummyu
#