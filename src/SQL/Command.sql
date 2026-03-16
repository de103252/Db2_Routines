--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

set current schema = SYSFUN#

-- Global variable to hold output from a utility invocation.
create variable db2util.command_output clob(4M)#

/*
*/

drop function db2command(command varchar(32704))#
drop function db2command(command varchar(32704), db2_member varchar(8), processing_type varchar(3))#

create function db2command(db2_command varchar(32704), db2_member varchar(8), processing_type varchar(3))
  returns clob
  modifies sql data
  not deterministic
begin
  declare rc     integer;

  declare db2_command_length integer;
  declare commands_executed, IFI_return_code, IFI_reason_code, excess_bytes,
          group_IFI_reason_code, group_excess_bytes, return_code integer default 0;
  declare message varchar(1331) default '';
  declare result clob ccsid unicode default '';

  -- Translate tab, linefeed and newline characters to spaces.
  set db2_command = translate(db2_command, ' ', x'090a0d');

  set db2_command_length = length(db2_command);
  
  call sysproc.admin_command_db2(db2_command, db2_command_length, processing_type,
  db2_member, commands_executed, IFI_return_code, IFI_reason_code , excess_bytes,
  group_IFI_reason_code, group_excess_bytes, return_code, message);
  
  if rc > 4 then
    signal sqlstate '5UA77' 
       set message_text = 'Command execution failed: ' || message;
  end if;
  
  for select text as line from sysibm.db2_cmd_output 
  do
    set result = result || line || x'0a';
  end for;          

  return result;
  
end
#

create function db2command(command varchar(32704), member varchar(8))
  returns clob
  modifies sql data
  not deterministic
return db2command(command, nullif(member, ''), cast(null as varchar(3)))

create function db2command(command varchar(32704))
  returns clob
  modifies sql data
  not deterministic
return db2command(command, cast(null as varchar(8)), cast(null as varchar(3)))
#
