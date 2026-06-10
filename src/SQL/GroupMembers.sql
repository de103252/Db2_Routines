-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

drop function sysfun.data_sharing_members()#

create function sysfun.data_sharing_members()
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