-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

drop function sysfun.set_client_info)#

create function sysfun.set_client_info(client_userid VARCHAR(255),
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