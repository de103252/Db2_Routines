-- =====================================================================
-- DB2 COMMAND EXECUTION FUNCTIONS
-- =====================================================================
-- Execute Db2 commands and retrieve their output programmatically.
--
-- Features:
-- - Execute Db2 commands via ADMIN_COMMAND_DB2 stored procedure
-- - Capture command output as CLOB
-- - Support for member-specific and group command execution
-- - Automatic whitespace normalization in commands
-- - Error handling with detailed messages
--
-- Functions:
-- - db2command(command, member, processing_type): Full control execution
-- - db2command(command, member): Execute on specific member
-- - db2command(command): Execute on current member
--
-- Usage Examples:
-- - Display database status: SELECT db2command('-DISPLAY DATABASE(*)') FROM SYSIBM.SYSDUMMYU
-- - Display group info: SELECT db2command('-DISPLAY GROUP', NULL, 'GRP') FROM SYSIBM.SYSDUMMYU
-- - Member-specific: SELECT db2command('-DISPLAY THREAD(*)', 'DB2A') FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

set current schema = SYSFUN
#

drop function db2command(command varchar(32704))
#

drop function db2command(command         varchar(32704), 
                         db2_member      varchar(8))
#

drop function db2command(command         varchar(32704), 
                         db2_member      varchar(8),
                         processing_type varchar(3))
#

drop variable db2util.command_output
#

-- Global variable to hold output from a utility invocation.
create variable db2util.command_output clob(4M)
#

create function db2command(db2_command     varchar(32704), 
                           db2_member      varchar(8),
                           processing_type varchar(3))
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

  set db2util.command_output = result;
  return result;
  
end
#

create function db2command(command varchar(32704), member varchar(8))
  returns clob
  modifies sql data
  not deterministic
return db2command(command, nullif(member, ''), cast(null as varchar(3)))
#

create function db2command(command varchar(32704))
  returns clob
  modifies sql data
  not deterministic
return db2command(command, cast(null as varchar(8)), cast(null as varchar(3)))
#
