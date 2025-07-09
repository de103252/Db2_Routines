-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

drop function db2utility(stmt clob ccsid unicode)#
drop function db2utility(utilid varchar(16), stmt clob ccsid unicode)#
drop variable utility_output#
commit#

/*
Global variable to hold output from a utility invocation.
*/
create variable utility_output clob(4M)
#

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
begin
  declare rc     integer;
  declare offs   integer default 1;
  declare stmt_x clob default '';
  declare result clob ccsid unicode default '';
  declare utilid varchar(12);
  
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
  set utility_output = result;

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
begin
  return db2utility(cast(null as varchar(16)), stmt);
end
#

grant execute on function db2utility(varchar(16), clob) to public
#

grant execute on function db2utility(clob) 
   to public
#
