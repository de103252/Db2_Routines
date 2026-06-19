-- =====================================================================
-- UPDATE SYSTEM PARAMETERS FUNCTION
-- =====================================================================
-- Update Db2 system parameters (ZPARMS) dynamically via SET SYSPARM command.
--
-- Features:
-- - Parse comma-separated parameter list (macro.parm=value format)
-- - Populate SYSIBM.SYSPARM_SETTINGS table
-- - Execute SET SYSPARM command for specified member and module
-- - Validates parameter format (requires macro.parm=value)
-- - Returns 0 on success
--
-- Parameters:
-- - db2_member: Target Db2 member name (VARCHAR(8))
-- - parameter_module: Parameter module name (VARCHAR(8))
-- - parameters: Comma-separated list of macro.parm=value pairs (VARCHAR(32704))
--
-- Parameter Format:
-- - Each parameter: macro.parm=value
-- - Multiple parameters: macro1.parm1=val1,macro2.parm2=val2
--
-- Usage Examples:
-- - Update single: SELECT update_sysparm('DB2A', 'DSNZPARM', 'DSN6SYSP.IDTHTOIN=120') FROM SYSIBM.SYSDUMMYU
-- - Update multiple: SELECT update_sysparm('DB2A', 'DSNZPARM', 'DSN6SYSP.IDTHTOIN=120,DSN6SYSP.CONTSTOR=5000') FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

drop function update_sysparm(parameters varchar(32704))
#

drop function update_sysparm(db2_member varchar(8), parameter_module varchar(8), parameters varchar(32704))
#

create function update_sysparm(db2_member varchar(8), parameter_module varchar(8), parameters varchar(32704))
  returns integer
  modifies sql data
  not deterministic
begin
  declare macro, param, value varchar(128);
  declare result clob default '';
  declare rc integer;
  
  delete from SYSIBM.SYSPARM_SETTINGS;
  for select seqno, token
        from xmltable('fn:tokenize(., ",")' passing parameters
                      columns seqno for ordinality
                            , token varchar(32704) path '.' )
  do                            
    if locate('.', token) <= 1 then
      signal sqlstate '5UA33' 
        set message_text = 'Invalid parameter format. Use macro.parm=val,...';
    end if;
    set macro = substr(token, 1, locate('.', token) - 1);

    set token = substr(token, locate('.', token) + 1);
    if locate('=', token) <= 1 then
      signal sqlstate '5UA33' 
        set message_text = 'Invalid parameter format. Use macro.parm=val,...';
    end if;
    set param = substr(token, 1, locate('=', token) - 1);

    set token = substr(token, length(param) + 2);
    set value = token;

    if length(value) = 0 then
      signal sqlstate '5UA33' 
        set message_text = 'Invalid parameter format. Use macro.parm=val,...';
    end if;

    insert into SYSIBM.SYSPARM_SETTINGS(rownum, macro, parameter, new_value)
                                values (seqno, macro, param, value);
  end for;                            
  CALL SYSPROC.ADMIN_UPDATE_SYSPARM (null, parameter_module, null, null, 'Y', rc);
  set db2util.utility_output = ''; 
  for select text from sysibm.UPDSYSPARM_MSG
  do
    if length(text) >= 3 and substr(text, 1, 3) = 'DSN' then
      set result = result || text || x'0a';
    else
      set result = result || substr(text, 2) || x'0a';
    end if;
  end for;
  set db2util.utility_output = result;
  return rc;
end
#

create function update_sysparm(parameters varchar(32704))
  returns integer
  modifies sql data
  not deterministic
return update_sysparm(cast(null as varchar(8)), cast(null as varchar(8)), parameters)
#

select update_sysparm('a.CTHREAD=b') from sysibm.sysdummyu#

select update_sysparm('', '',
  'DSN6SYSP.CTHREAD=666,' ||
  'DSN6SPRM.TABLE_COL_NAME_EXPANSION=OFF'
) from sysibm.sysdummyu#

select update_sysparm('', '',
  'DSN6SPRM.TABLE_COL_NAME_EXPANSION=OFF'
) from sysibm.sysdummyu#

select * from SYSIBM.SYSPARM_SETTINGS#

select db2util.utility_output from sysibm.sysdummyu#
