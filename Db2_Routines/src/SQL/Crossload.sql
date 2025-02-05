--<ScriptOptions statementTerminator="#"/>

drop function crossload(sourceschema varchar(128),     
                        targetschema varchar(128))#     

drop function crossload(sourceschema varchar(128), 
                        sourcetable  varchar(128), 
                        targetschema varchar(128), 
                        targettable  varchar(128))#

drop function crossload(sourceselect varchar(32704), 
                        targetschema varchar(128),
                        targettable varchar(128), 
                        tmpspace integer)#
                        

drop function db2utility(stmt clob ccsid unicode)#
drop variable utility_output#
commit#

/*
Global variable to hold output from a utility invocation.
*/
create variable utility_output clob(4M)
#

commit#

/*
Run a Db2 utility.
*/
create function db2utility(stmt clob ccsid unicode)
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
  
  -- Create a random utility ID
  set utilid = 'UTIL' || digits(decimal(rand() * 100000, 5));
  
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

grant execute on function db2utility(clob) 
   to public
#


create function crossload(sourceselect varchar(32704), 
                          targetschema varchar(128), 
                          targettable  varchar(128), 
                          tmpspace     integer)
  returns integer
  modifies sql data
begin
  set tmpspace = min(tmpspace, 5);
  return db2utility('
  TEMPLATE UT1 DSN &US..TEMP.SYSUT1.&UQ.
               DISP(NEW,DELETE,DELETE) 
               SPACE(' || tmpspace || ',' || tmpspace || ') MB                                                
  TEMPLATE SO  DSN &US..TEMP.SORTOUT.&UQ.
               DISP(NEW,DELETE,DELETE) 
               SPACE(' || tmpspace || ',' || tmpspace || ') MB                                                  

  EXEC SQL                                               
   DECLARE C1 CURSOR FOR ' || sourceselect || ';     
  ENDEXEC  
      
  LOAD DATA INCURSOR(C1)
  WORKDDN(UT1,SO) 
  LOG(NO)
  SORTDEVT SYSALLDA 
  REPLACE 
  STATISTICS REPORT(YES)
  INTO TABLE "' || targetschema || '"."' || targettable || '"'
);
end
#

create function crossload(sourceschema varchar(128), 
                          sourcetable  varchar(128), 
                          targetschema varchar(128), 
                          targettable  varchar(128))
  returns integer
  modifies sql data
begin
  declare columns varchar(32704);
  declare tmpspace integer;
  
  -- Find columns that are in both tables, and are updateable
  -- in the target table.
  with
  cols as (
  select tb.creator as tbcreator
       , tb.name as tbname
       , co.name
       , co.colno
       , co.updates
       , co.default
    from sysibm.systables  tb
    join sysibm.syscolumns co
      on (tb.creator, tb.name) = (co.tbcreator, co.tbname)
   order by colno
  ),
  loadcols as (
  select name
    from cols
   where (tbcreator, tbname) = (targetschema, targettable)
  intersect
  select name
    from cols
   where (tbcreator, tbname) = (sourceschema, sourcetable)
  except
  select name
    from cols
   where (tbcreator, tbname) = (targetschema, targettable)
     and (updates <> 'Y' or default in ('A', 'E', 'I'))
  )
  select listagg(name, ', ')
    into columns
    from loadcols;

  if columns is null then
    signal sqlstate '5UA99' 
       set message_text = 'Source or target table does not exist, or no common columns';
  
  end if;
  
  -- Estimate temp space from real-time statistics.
  select min(coalesce(sum(st.space), 1024) / 1024, 1)
    into tmpspace
    from sysibm.systables tb
    join sysibm.systablespace ts
      on (tb.dbname, tb.tsname) = (ts.dbname, ts.name)
    join sysibm.systablespacestats st
      on (ts.dbid, ts.psid) = (st.dbid, st.psid)
   where (tb.creator, tb.name) = (sourceschema, sourcetable);
  
  -- Run the LOAD utility.
  return crossload('SELECT ' || columns || 
                   ' FROM "' || sourceschema || 
                   '"."'     || sourcetable || '"',
                   targetschema,
                   targettable,
                   tmpspace);
end
#

create function crossload(sourceschema varchar(128),     
                          targetschema varchar(128))     
  returns integer               
  version v1                                                    
  language sql                                                  
  parameter ccsid unicode                                       
  not deterministic                                             
  external action   
  modifies sql data                                            
  returns null on null input                                          
begin                                                             
  declare maxrc integer default 0;
  declare tmp_utility_output clob(4M) default '';
  
  if sourceschema is not distinct from targetschema then
    signal sqlstate '5UA88' 
       set message_text = 'Source and target schemas must be different';
    return 12;
  end if;
  
  -- Find all tables that are in both source and target schema.
  -- Iterate over all tables, and invoke the single-table crossload
  -- function for each.                                
  for select name from sysibm.systables                          
       where creator = sourceschema               
      intersect                                                     
      select name from sysibm.systables                          
       where type = 'T' and creator = targetschema
  do             
    set tmp_utility_output = utility_output;                                               
    set maxrc = max(maxrc,                                     
                    CROSSLOAD(sourceschema, name, targetschema, name));
    set utility_output = tmp_utility_output || utility_output || x'0a';                                            
  end for;                                                     
  return maxrc;                                               
end
#

grant execute on function bg05016.crossload(varchar(128),varchar(128)) 
   to public
#

commit
#

-- Test ----------------------------------------------------------------
select crossload('select * from dsn81210.emp', 
                 current sqlid, 'EMP',
                 100) as rc
     , utility_output
  from sysibm.sysdummyu
#

select crossload('DSN81210', current sqlid) as rc
     , utility_output
  from sysibm.sysdummyu
#

select crossload('DSN81210', 'EMP', current sqlid, 'EMP') as rc
     , utility_output
  from sysibm.sysdummyu
#
