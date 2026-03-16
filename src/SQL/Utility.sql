--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

set current schema = SYSFUN#
drop function db2utility(stmt clob ccsid unicode)#
drop function db2utility(utilid varchar(16), stmt clob ccsid unicode)#
drop function terminate_utility(utilid varchar(16))#
drop variable db2util.utility_id#
drop variable db2util.utility_output#
commit#

-- Global variable to hold utility ID.
create variable db2util.utility_id varchar(16)#

-- Global variable to hold output from a utility invocation.
create variable db2util.utility_output clob(4M)#

commit#


/*
Run Db2 utility statements.

Parameters:
utilid -- Utility ID or NULL. If NULL, the procedure generates a random utility ID.
stmt   -- The utility statement(s).

Returns:
The highest reason code from running the utility. If the reason code was greater than 4,
signals SQLSTATE 5UA99.
The utility output is returned in global variable UTILITY_OUTPUT.
*/
create function db2utility(utilid varchar(16), stmt clob ccsid unicode)
  returns integer
  modifies sql data
  not deterministic
begin
  declare rc     integer;
  declare offs   integer default 1;
  declare stmt_x clob default '';
  declare result clob ccsid unicode default '';
  
  -- Translate tab, linefeed and newline characters to spaces.
  -- Since TRANSLATE does not work on LOBs, we need to do this in a loop.
  while offs < length(stmt) do
    set stmt_x = stmt_x ||
                 translate(varchar(substring(stmt, 
                                     offs, 
                                     min(length(stmt) - offs + 1, 4096), 
                                     codeunits32), 4096),
                           ' ',
                           x'090a0d');
    set offs = offs + 4096;
  end while;
  
  if utilid is null then
    -- Create a random utility ID
    set utilid = 'UTIL' || digits(decimal(rand() * 100000, 5));
  end if;
  
  -- Remember the possibly generated utility ID in global variable
  set db2util.utility_id = utilid;
  
  -- Call the utility
  call sysproc.dsnutilu(utilid,
                        'NO',
                        stmt_x,
                        rc);
                        
  -- Collect the utility output, ignoring column 1.                        
  for select substr(text, 2) as line from sysibm.sysprint 
  do
    set result = result || line || x'0a';
  end for;          

  -- Set the global variable.
  set db2util.utility_output = result;

  -- Signal an error if the utility terminated with an error return code.
  if rc > 4 then
    signal sqlstate '5UA99' 
       set message_text = 'Utility terminated with RC = ' || varchar(rc);
  end if;
                          
  return rc;  
end
#

create function db2utility(stmt clob ccsid unicode)
  returns integer
  modifies sql data
  not deterministic
begin
  return db2utility(cast(null as varchar(16)), stmt);
end
#

grant execute on function db2utility(varchar(16), clob) to public
#

grant execute on function db2utility(clob) 
   to public
#

/*
drop function terminate_utility(utilid varchar(16))
#

create function terminate_utility(utilid varchar(16))
--  returns integer
returns varchar(1331)
  modifies sql data
  not deterministic
begin
  declare db2_command varchar(64);
  declare db2_command_length integer;
  declare db2_member varchar(8) default null;
  declare processing_type varchar(3) default '';
  declare commands_executed, IFI_return_code, IFI_reason_code, excess_bytes,
          group_IFI_reason_code, group_excess_bytes, return_code integer default 0;
  declare message varchar(1331) default '';
  
  set db2_command = '-TERM UTILITY(' || utilid || ')';
  set db2_command_length = length(db2_command);
  
  call sysproc.admin_command_db2(db2_command, 100, processing_type,
  db2_member, commands_executed, IFI_return_code, IFI_reason_code , excess_bytes,
  group_IFI_reason_code, group_excess_bytes, return_code, message);
  
  return message; --return_code * 256 + ifi_return_code;
  
  insert into sysibm.sysprint values(1, digits(commands_executed));
  insert into sysibm.sysprint values(2, message);
  set db2util.utility_output = message;

--  return ifi_return_code;
end
#
*/