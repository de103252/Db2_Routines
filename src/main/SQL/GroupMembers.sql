-- =====================================================================
-- DATA SHARING GROUP MEMBERS FUNCTION
-- =====================================================================
-- Retrieve list of all members in the Db2 data sharing group.
--
-- Features:
-- - Executes -DISPLAY GROUP command via ADMIN_COMMAND_DB2
-- - Returns comma-separated list of member names
-- - Uses SYSIBM.DATA_SHARING_GROUP catalog table
-- - Non-deterministic (reflects current group state)
--
-- Usage Examples:
-- - Get all members: SELECT data_sharing_members() FROM SYSIBM.SYSDUMMYU
-- - Count members: SELECT LENGTH(data_sharing_members()) - LENGTH(REPLACE(data_sharing_members(), ',', '')) + 1 FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

drop function data_sharing_members()#

create function data_sharing_members()
  returns varchar(32704)
  language sql
  not deterministic
  modifies sql data
begin
  declare db2_command varchar(64);
  declare db2_command_length integer;
  declare db2_member varchar(8) default null;
  declare commands_executed, IFI_return_code, IFI_reason_code, excess_bytes,
          group_IFI_reason_code, group_excess_bytes, return_code integer default 0;
  declare message varchar(1331) default '';
  
  set db2_command = '-DISPLAY GROUP';
  set db2_command_length = length(db2_command);
  
  call sysproc.admin_command_db2(db2_command, db2_command_length, 'GRP',
  db2_member, commands_executed, IFI_return_code, IFI_reason_code , excess_bytes,
  group_IFI_reason_code, group_excess_bytes, return_code, message);
  
  return (select listagg(cast(db2_member as varchar(8))) from SYSIBM.DATA_SHARING_GROUP);
end
#

select data_sharing_members() from sysibm.sysdummyu;

  call sysproc.admin_command_db2('-DISPLAY GROUP', 100, 'GRP',
  null, null, null, null, null, null, null, null, null);
  select * from sysibm.data_sharing_group;
  
  return (select listagg(cast(db2_member as varchar(8))) from SYSIBM.DATA_SHARING_GROUP);