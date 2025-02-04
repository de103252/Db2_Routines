-- CONNECTION: url=jdbc:db2://newg:5045/DALLASD
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

set current schema = 'UTIL'
#

SET CURRENT SQLID = 'ADCDMST'#

CREATE VARIABLE utility_output clob(4M)#

drop function crossload(sourceschema varchar(128),     
                        targetschema varchar(128))#     

drop function crossload(sourceselect varchar(32704), 
                        targetschema varchar(128),
                        targettable varchar(128), 
                        tmpspace integer)#
drop function utility(stmt varchar(32704) ccsid unicode)#

create function utility(stmt varchar(32704) ccsid unicode)
  returns integer
  modifies sql data
begin
  declare rc integer;
  declare result clob ccsid unicode;
  declare utilid VARCHAR(12);
  
  set utilid = 'UTIL' || digits(decimal(rand() * 100000, 5));
  call sysproc.dsnutilu(utilid,
                        'NO',
                        translate(stmt, ' ', x'090a0d'),
                        rc);
                        
  set result = 'Utility terminated with RC = ' || varchar(rc) || x'0a';
  if rc > 0 then
    signal sqlstate '01UTL' 
       set message_text = 'Utility terminated with RC = ' || varchar(rc);
  end if;
                          
  for select substr(text, 2) as line from sysibm.sysprint 
  do
    set result = result || line || x'0a';
  end for;          
  SET util.utility_output = RESULT;
  if rc >= 8 then
    signal sqlstate 'UT007' 
       set message_text = 'Utility terminated with RC = ' || varchar(rc);
  end if;
  return rc;  
end
#

grant execute on function utility(varchar(32704)) 
   to public
#

/*
drop function crossload(sourceselect varchar(32704), 
                        targetschema varchar(128), 
                        targettable varchar(128), 
                        tmpspace integer)
#
*/


create function crossload(sourceselect varchar(32704), 
                          targetschema varchar(128), 
                          targettable  varchar(128), 
                          tmpspace     integer)
  returns integer
  modifies sql data
begin
  set tmpspace = coalesce(nullif(tmpspace, 0), 100);
  return (SELECT utility('
            TEMPLATE UT1 DSN &US..TEMP.SYSUT1.&UQ.
                         DISP(NEW,DELETE,DELETE) 
                         SPACE(' || tmpspace || ',' || tmpspace || ') MB                                                
            TEMPLATE SO  DSN &US..TEMP.SORTOUT.&UQ.
                         DISP(NEW,DELETE,DELETE) 
                         SPACE(' || tmpspace || ',' || tmpspace || ') MB                                                  
          
            EXEC SQL                                               
             DECLARE C1 CURSOR FOR ' concat sourceselect concat ';     
            ENDEXEC  
                
            LOAD DATA INCURSOR(C1)
            WORKDDN(UT1,SO) 
            LOG(NO)
            SORTDEVT SYSALLDA 
            REPLACE 
            STATISTICS REPORT(YES)
            INTO TABLE ' concat targetschema concat '.' concat targettable
         )
         from sysibm.sysdummyu);
end
#

DROP  function crossload(sourceschema varchar(128),
                          sourcetable  varchar(128), 
                          targetschema varchar(128), 
                          targettable  varchar(128))
#

/*
Loads all rows from table sourceschema.sourcetable
into table targetschema.targettable.
The source and target tables need not have the exact same structure;
the function loads only columns that are common to both tables and that
are not declared GENERATED ALWAYS in the target table.
 */
create function crossload(sourceschema varchar(128),
                          sourcetable  varchar(128), 
                          targetschema varchar(128), 
                          targettable  varchar(128))
  returns integer
  modifies sql data
begin  
  declare tmpspace integer;
  declare sourceselect varchar(32704);
  
  select coalesce(max(1, sum(st.space)) / 1024, 100) space_mb
    into tmpspace
    from sysibm.systables     tb
    join sysibm.systablespace ts
      on (tb.dbname, tb.tsname) = (ts.dbname, ts.name)
    join sysibm.systablespacestats st
      on (ts.dbname, ts.name) = (st.dbname, st.name)
   where (tb.creator, tb.name) = (sourceschema, sourcetable);
   
   WITH
   cols0 AS (
   SELECT tb.creator, tb.name, co.name colname, co.colno, co.updates, co.default
     FROM "SYSIBM".systables  tb
     JOIN "SYSIBM".syscolumns co
       ON (tb.creator, tb.name) = (co.tbcreator, co.tbname)
    ORDER BY colno
   ),
   cols AS (
   SELECT colname
     FROM cols0
    WHERE (creator, name) = (sourceschema, sourcetable)
    INTERSECT 
   SELECT colname
     FROM cols0
    WHERE (creator, name) = (targetschema, targettable)
    EXCEPT 
   SELECT colname
     FROM cols0
    WHERE (creator, name) = (targetschema, targettable)
      AND updates = 'N'
       OR DEFAULT IN ('A', 'E', 'I')
   )
   SELECT 'SELECT ' || listagg(colname, ', ')
       || '  FROM "' || sourceschema || '"."' || sourcetable || '"'
     INTO sourceselect
     FROM cols;
  RETURN crossload(sourceselect,
                    targetschema,
                    targettable,
                    tmpspace);
end#

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
  declare result clob default '' ;
  declare maxrc integer default 0;
  DECLARE tmp_output clob(4M) DEFAULT '';
  DECLARE rc integer DEFAULT 0;
  
  -- Find all tables that are in both source and target schema.
  -- Try to determine allocated space of the source table.
  -- Iterate over all tables, and invoke the single-table crossload
  -- function for each.                                
  for 
    with tables as (
      select name from sysibm.systables                          
       where type = 'T' and creator = sourceschema               
      intersect                                                     
      select name from sysibm.systables                          
       where type = 'T' and creator = targetschema
    )
    select tb.name
         , coalesce(max(1, sum(st.space) / 1024), 100) space_mb
      from tables               stb
      join sysibm.systables     tb
        on (sourceschema, stb.name) = (tb.creator, tb.name)
      join sysibm.systablespace ts
        on (tb.dbname, tb.tsname) = (ts.dbname, ts.name)
      join sysibm.systablespacestats st
        on (ts.dbname, ts.name) = (st.dbname, st.name)
     group by tb.dbname, tb.name               
  do                           
    SET tmp_putput = util.utility_output;
    set rc = max(rc, CROSSLOAD('select * from ' || sourceschema || '.' || name , 
    targetschema ,                                              
    name ,                                                      
    cast(space_mb AS integer))) ;        
    SET util.utility_output = tmp_putput || util.utility_output;
  end for ;                                                     
  return rc ;                                               
end
#

grant execute on function crossload(varchar(128),varchar(128)) 
   to public
   #


-- Test ----------------------------------------------------------------
select crossload('select * from dsn81310.emp', current sqlid, 'EMP', 100)
  from sysibm.sysdummyu
#

select crossload('DSN81310', 'BG05016')
  from sysibm.sysdummyu
#

SELECT util.crossload('DSN81310', 'EMPO', 'ADCDMST', 'EMP')
  FROM SYSIBM.sysdummyu;
  
SELECT util.utility_output 
  FROM SYSIBM.sysdummyu
#