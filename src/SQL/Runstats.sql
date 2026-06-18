-- =====================================================================
-- RUNSTATS UTILITY EXECUTION FUNCTION
-- =====================================================================
-- Execute RUNSTATS utility against tables or tablespaces with pattern matching.
--
-- Features:
-- - Pattern-based table or tablespace selection (regular expressions)
-- - Custom RUNSTATS statement options
-- - Batch execution across multiple objects
-- - Returns highest return code from all executions
-- - Returns utility output in global variable db2util.utility_output
--
-- Parameters:
-- - what: 'TABLES' or 'DATABASE' (tablespace)
-- - schema_pattern: Schema name pattern (supports regular expressions)
-- - name_pattern: Table/tablespace name pattern (supports regular expressions)
-- - statement: RUNSTATS options string (default: 'USE PROFILE SORTDEVT SYSALLDA')
--
-- Usage Examples:
-- - All tables in schema: SELECT runstats('TABLES', 'MYSCHEMA', '%', 'TABLESPACE ALL') FROM SYSIBM.SYSDUMMYU
-- - Specific pattern: SELECT runstats('TABLES', 'PROD%', 'CUST%', 'TABLESPACE ALL INDEX ALL') FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#
    
drop function runstats(what           varchar(16),
                       schema_pattern varchar(1024), 
                       name_pattern   varchar(1024),
                       statement      varchar(16384))#

/*
Arguments:
WHAT -- Either 'TABLES' or 'DATABASE'
SCHEMA_PATTERN -- e
*/
create function runstats(what           varchar(16),
                         schema_pattern varchar(1024), 
                         name_pattern   varchar(1024),
                         statement      varchar(16384))
  returns integer
  language sql
  not deterministic
  modifies sql data
begin
  declare utilid varchar(16);
  declare utstmt clob;
  declare sysprint clob default '';
  declare retcode integer;
  
  case upper(what)
  when 'TABLES' then
  select 'LISTDEF RSLIST ' 
          || xmlserialize(xmlagg(
                             xmltext(' INCLUDE TABLE ' || 
                                     trim(creator) || 
                                     '."' || 
                                     name || '"')) 
                          as clob) 
          || ' RUNSTATS TABLESPACE LIST RSLIST TABLE '
          || coalesce(nullif(statement, ''), 'USE PROFILE SORTDEVT SYSALLDA')
    into utstmt
    from sysibm.systables
   where type = 'T'
         and creator like schema_pattern
         and (   nullif(name_pattern, '') is null
              or name like name_pattern
             );
  when 'DATABASE' then
  select 'LISTDEF RSLIST ' || 
         case when nullif(name_pattern, '') is null then
         'INCLUDE TABLESPACES DATABASE ' || schema_pattern
         else
         'INCLUDE ' || schema_pattern || '.' || name_pattern
         end ||
         ' RUNSTATS TABLESPACE LIST RSLIST TABLE '
          || coalesce(nullif(statement, ''), 'USE PROFILE SORTDEVT SYSALLDA')
    into utstmt
    from sysibm.sysdatabase
   where name = schema_pattern;
  else
    signal sqlstate '77777'       
       set message_text = 
        'Value of argument 1 is not valid';
  end case;
  return db2utility(utstmt);
end
#

--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

select runstats('TABLES', 'DSN81310', 'EMP%', '')
  from sysibm.sysdummyu
;

select db2util.utility_output
  from sysibm.sysdummyu
;

