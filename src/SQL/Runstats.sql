-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

/*
Runs the RUNSTATS utility against the specified set of 
tables or tablespaces.
*/
    
drop    function runstats(what varchar(16),
                         schema_pattern varchar(1024), 
                         name_pattern varchar(1024),
                         statement varchar(16384))#

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
          || ' RUNSTATS TABLESPACE LIST RSLIST TABLE'
          || coalesce(nullif(statement, ''), ' USE PROFILE SORTDEVT SYSALLDA')
    into utstmt
    from sysibm.systables
   where creator like schema_pattern
     and type = 'T'
     and (nullif(name_pattern, '') is null
          or name like name_pattern);
  when 'DATABASE' then
  select 'LISTDEF RSLIST ' || 
         case when nullif(name_pattern, '') is null then
         'INCLUDE TABLESPACES DATABASE ' || schema_pattern
         else
         'INCLUDE ' || schema_pattern || '.' || name_pattern
         end ||
         ' RUNSTATS TABLESPACE LIST RSLIST TABLE'
          || coalesce(nullif(statement, ''), ' USE PROFILE SORTDEVT SYSALLDA')
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

select runstats('DATABASE', 'DSN8D13L', '', '') 
     , utility_output
  from sysibm.sysdummyu
#
select substr(text, 2) from sysibm.sysprint#

#

