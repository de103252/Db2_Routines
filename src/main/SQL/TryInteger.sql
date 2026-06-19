-- =====================================================================
-- TRY CONVERSION FUNCTIONS (INTEGER TYPES)
-- =====================================================================
-- Safe integer conversion functions that return NULL instead of errors.
--
-- Features:
-- - try_integer: Convert string to INTEGER
-- - try_smallint: Convert string to SMALLINT
-- - try_bigint: Convert string to BIGINT
-- - Returns NULL on conversion failure (no exception thrown)
-- - Raises SQL warning (SQLSTATE 02018) on failure
-- - Allows leading and trailing blanks
-- - Deterministic with no external actions
--
-- Functions:
-- - try_integer(str VARCHAR(255)): Returns INTEGER or NULL
-- - try_smallint(str VARCHAR(255)): Returns SMALLINT or NULL
-- - try_bigint(str VARCHAR(255)): Returns BIGINT or NULL
--
-- Usage Examples:
-- - Valid conversion: SELECT try_integer('42') FROM SYSIBM.SYSDUMMYU  -- Returns 42
-- - Invalid conversion: SELECT try_integer('abc') FROM SYSIBM.SYSDUMMYU  -- Returns NULL
-- - With blanks: SELECT try_integer('  123  ') FROM SYSIBM.SYSDUMMYU  -- Returns 123
-- =====================================================================

drop function try_integer(str varchar(255))#
drop function try_smallint(str varchar(255))#
drop function try_bigint(str varchar(255))#

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

create function try_integer(str varchar(255))
  returns integer
  returns null on null input
  parameter ccsid unicode
  deterministic
  no external action
begin
  declare exit handler for sqlstate '22018' 
  begin 
    signal sqlstate '02018'
       set message_text = '‪THE‬‎ ‪VALUE‬‎ ‪OF‬‎ ‪A‬‎ ‪STRING‬‎ ‪ARGUMENT‬‎ ‪WAS‬‎ ‪NOT‬‎ ' ||
                          '‪ACCEPTABLE‬‎ ‪TO‬‎ ‪THE‬‎ ‪SYSIBM‬‎.‪INTEGER‬‎ ‪FUNCTION‬‎.‪‬‎';
    return null;
  end;
  return int(str);
end
#

create function try_smallint(str varchar(255))
  returns smallint
  returns null on null input
  parameter ccsid unicode
  deterministic
  no external action
begin
  declare exit handler for sqlstate '22018' 
  begin 
    signal sqlstate '02018'
       set message_text = '‪THE‬‎ ‪VALUE‬‎ ‪OF‬‎ ‪A‬‎ ‪STRING‬‎ ‪ARGUMENT‬‎ ‪WAS‬‎ ‪NOT‬‎ ' ||
                          '‪ACCEPTABLE‬‎ ‪TO‬‎ ‪THE‬‎ ‪SYSIBM‬‎.‪SMALLINT‬‎ ‪FUNCTION‬‎.‪‬‎';
    return null;
  end;
  return smallint(str);
end
#

create function try_bigint(str varchar(255))
  returns bigint
  returns null on null input
  parameter ccsid unicode
  deterministic
  no external action
begin
  declare exit handler for sqlstate '22018' 
  begin 
    signal sqlstate '02018'
       set message_text = '‪THE‬‎ ‪VALUE‬‎ ‪OF‬‎ ‪A‬‎ ‪STRING‬‎ ‪ARGUMENT‬‎ ‪WAS‬‎ ‪NOT‬‎ ' ||
                          '‪ACCEPTABLE‬‎ ‪TO‬‎ ‪THE‬‎ ‪SYSIBM‬‎.BIGINT ‪FUNCTION‬‎.‪‬‎';
    return null;
  end;
  return bigint(str);
end
#

-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;
