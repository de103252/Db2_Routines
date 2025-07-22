-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

/*
Copy table contents from one table to another via the
Db2 cross-load function.
*/

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
                        

/*
 * Copy table contents from one table to another.
 * 
 * Parameters:
 * sourceselect -- A SELECT statement that returns the data to be
 *                 copied from the source table.
 * targetschema -- The schema name of the target table.
 * targettable  -- The name of the target table.
 * tempspace    -- Temp space in MB to be allocated for the LOAD
 *                 utility. Defaults to 5 MB if set to NULL.
 */
create function crossload(sourceselect varchar(32704), 
                          targetschema varchar(128), 
                          targettable  varchar(128), 
                          tmpspace     integer)
  returns integer
  modifies sql data
begin
  set tmpspace = min(tmpspace, 5);
  return db2utility(
  'TEMPLATE UT1 DSN &US..TEMP.SYSUT1.&UQ.
               DISP(NEW,DELETE,DELETE) ' ||
               case when tmpspace is null 
                    then 'CYL'
                    else 'SPACE(' || tmpspace || ',' || tmpspace || ') MB' 
               end ||
  'TEMPLATE SO  DSN &US..TEMP.SORTOUT.&UQ.
                DISP(NEW,DELETE,DELETE) ' ||
               case when tmpspace is null 
                    then 'CYL'
                    else 'SPACE(' || tmpspace || ',' || tmpspace || ') MB' 
               end ||
  'EXEC SQL                                               
     DECLARE C1 CURSOR FOR ' || sourceselect || ';     
   ENDEXEC  
      
   LOAD DATA INCURSOR(C1) WORKDDN(UT1,SO) LOG(NO)
   SORTDEVT SYSALLDA 
   REPLACE 
   STATISTICS REPORT(YES)
   INTO TABLE "' || targetschema || '"."' || targettable || '"'
);
end
#

/*
 * Copy table contents from one table to another.
 * Copies only columns that are common to both tables
 * and that are updateable in the target table.
 * The amount of temp space needed for the LOAD utility
 * is estimated from real-time statistics on the
 * source table.
 * 
 * Parameters:
 * sourceschema -- The schema name of the source table.
 * sourcetable  -- The name of the source table.
 * targetschema -- The schema name of the target table.
 * targettable  -- The name of the target table.
 * tempspace    -- Temp space in MB to be allocated for the LOAD
 *                 utility. Defaults to 5 MB if set to NULL.
 * 
 */
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
  tb as (
  select distinct 
         t2.creator as creator
       , t2.name as name
       , t2.type as type
    from sysibm.systables  t1
    join sysibm.systables  t2
      on (t2.creator, t2.name) 
         = 
         (case t1.type when 'A' then t1.tbcreator else t1.creator end,
          case t1.type when 'A' then t1.tbname    else t1.name    end)
   where t1.type not in ('D', 'G', 'P', 'X')
  ),
  cols as (
  select tb.creator as tbcreator
       , tb.name as tbname
       , co.name
       , co.colno
       , co.updates
       , co.default
    from                   tb
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

/*
 * Copy table contents from one schema to another schema.
 * Source and target schemas must be different.
 * This function copies the contents of all tables or views
 * in the source schema for which a table with the same
 * name exists in the target schema.
 * 
 * Parameters:
 * sourceschema -- The schema name of the source tables.
 * targetschema -- The schema name of the target tables.
 *
 * Returns:
 * The number of tables that were copied.
 */
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
  declare count integer default 0;
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
         and name not like 'DSN_%'
         and name not like 'PLAN_TABLE'
      intersect                                                     
      select name from sysibm.systables                          
       where type = 'T' and creator = targetschema
  do             
    set count = count + 1;
    set tmp_utility_output = utility_output;                                               
    set maxrc = max(maxrc,                                     
                    CROSSLOAD(sourceschema, name, targetschema, name));
    set utility_output = tmp_utility_output || utility_output || x'0a';                                            
  end for;      
  return count;
end
#

grant execute on function crossload(varchar(128),     
                                    varchar(128))
   to public#     

grant execute on function crossload(varchar(128), 
                                    varchar(128), 
                                    varchar(128), 
                                    varchar(128))
   to public#     

grant execute on function crossload(varchar(32704), 
                                    varchar(128),
                                    varchar(128), 
                                    integer)
   to public#     

commit
#

-----------------------------------------------------------------------
-- Test
-----------------------------------------------------------------------

create table emp like dsn81310.emp#

select crossload('select * from dsn81310.emp', 
                 current sqlid, 'EMP',
                 100) as rc
  from sysibm.sysdummyu
#
select utility_output
  from sysibm.sysdummyu
#

select * from emp
#

select crossload('DSN81310', current sqlid) as rc
     , utility_output
  from sysibm.sysdummyu
#
select utility_output
  from sysibm.sysdummyu
#

select crossload('DSN81310', 'EMP', current sqlid, 'EMP') as rc
     , utility_output
  from sysibm.sysdummyu
#
