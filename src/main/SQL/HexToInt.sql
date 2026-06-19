-- =====================================================================
-- HEXADECIMAL TO INTEGER CONVERSION FUNCTION
-- =====================================================================
-- Convert hexadecimal string to integer value (inverse of HEX function).
--
-- Features:
-- - Accepts upper or lowercase hex digits (0-9, A-F, a-f)
-- - Returns BIGINT for large value support
-- - Validates hex string format
-- - Returns NULL on NULL input
-- - Deterministic with no external actions
--
-- Error Handling:
-- - SQLSTATE 72606: Invalid hexadecimal constant
-- - SQLSTATE 22003: Numeric overflow (value exceeds BIGINT range)
--
-- Usage Examples:
-- - Convert FF to 255: SELECT hextoint('FF') FROM SYSIBM.SYSDUMMYU
-- - Convert max int: SELECT hextoint('7FFFFFFF') FROM SYSIBM.SYSDUMMYU
-- - Handle NULL: SELECT hextoint(NULL) FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

drop function hextoint(s varchar(32704))#

create function hextoint(s varchar(32704))
  returns bigint
  returns null on null input
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
