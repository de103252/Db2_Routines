-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

drop function unloadcsv(table_name varchar(1024), path_name varchar(1024))#

create function unloadcsv(table_name varchar(1024), path_name varchar(1024))
  returns integer
  language sql
  not deterministic
  modifies sql data
begin
  declare utilid varchar(16);
  declare utstmt clob;
  declare sysprint clob default '';
  declare retcode integer;
  
  set utilid = 'UCSV' || varchar_format(current timestamp, 'YYMMDDHH24MISS');
  
  set utstmt = 'TEMPLATE CSVFILE PATH ' || path_name
      || ' UNLOAD DATA FROM TABLE ' || table_name
      || ' UNLDDN CSVFILE'
      || ' UNICODE'
      || ' DELIMITED';
      
  call sysproc.dsnutilv(utilid, 'NO', utstmt, retcode);
  /*
  for select text from sysibm.sysprint order by seqno do
    set sysprint = sysprint || substr(text, 2) || x'0a';
  end for;
  return sysprint;
  */
  if retcode > 4 then
    signal sqlstate '77777'       
       set message_text = 
        'DSNUTILV ended with RC=' || retcode;
  end if;
  return retcode;
end
#

select unloadcsv('ADCDMST.EMP', '/u/adcdmst/emp.txt') 
  from sysibm.sysdummyu#
select xmlserialize(xmlagg(xmltext(substr(text, 2) || x'0a')) as clob) from sysibm.sysprint#
  
