-- =====================================================================
-- SET CLIENT INFO FUNCTION
-- =====================================================================
-- Set client information for workload management and monitoring.
--
-- Features:
-- - Wrapper for SYSPROC.WLM_SET_CLIENT_INFO stored procedure
-- - Sets client userid, workstation name, application name, and accounting string
-- - Used for workload classification and monitoring
-- - Returns 0 on success
--
-- Parameters:
-- - client_userid: Client user ID (VARCHAR(255))
-- - client_wrkstnname: Client workstation name (VARCHAR(255))
-- - client_applname: Client application name (VARCHAR(255))
-- - client_acctstr: Client accounting string (VARCHAR(255))
--
-- Usage Examples:
-- - Set all info: SELECT set_client_info('USER1', 'WS001', 'MYAPP', 'ACCT123') FROM SYSIBM.SYSDUMMYU
-- - Set partial: SELECT set_client_info('USER1', '', '', '') FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

drop function set_client_info(client_userid VARCHAR(255),
client_wrkstnname VARCHAR(255),
client_applname VARCHAR(255),
client_acctstr VARCHAR(255))#

create function set_client_info(client_userid VARCHAR(255),
client_wrkstnname VARCHAR(255),
client_applname VARCHAR(255),
client_acctstr VARCHAR(255))

  returns integer
  language sql
  not deterministic
  modifies sql data
begin
  call sysproc.wlm_set_client_info(client_userid, client_wrkstnname, client_applname, client_acctstr);
  return 0;
end
#

select set_client_info('A', '', '', '') from sysibm.sysdummyu