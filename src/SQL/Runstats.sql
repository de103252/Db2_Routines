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
create function runstats(what varchar(16),
                         schema_pattern varchar(1024), 
                         name_pattern varchar(1024),
                         statement varchar(16384))
  returns clob -- or integer, if interested only in the return code
  language sql
  not deterministic
  modifies sql data
begin
  declare utilid varchar(16);
  declare utstmt clob;
  declare sysprint clob default '';
  declare retcode integer;
  
  set utilid = 'RS' || varchar_format(current timestamp, 'YYMMDDHH24MISS');
  
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
  call sysproc.dsnutilv(utilid, 'NO', utstmt, retcode);

  if retcode > 4 then
    signal sqlstate '77777'       
       set message_text = 
        'DSNUTILV return code =' || retcode;
  end if;
  
  for select text from sysibm.sysprint order by seqno do
    set sysprint = sysprint || substr(text, 2) || x'0a';
  end for;
  return sysprint; -- or retcode
end
#

select runstats('DATABASE', 'DSN8D13L', '', '') 
  from sysibm.sysdummyu
#
select substr(text, 2) from sysibm.sysprint#

#

