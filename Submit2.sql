--<ScriptOptions statementTerminator="#"/>

drop function submit(jcl clob, from varchar(80), to varchar(80))#
create function submit(jcl clob ccsid unicode, from varchar(80), to varchar(80))
  returns clob
  external action
  modifies sql data
  called on null input
begin
  declare jobid char(8);
  declare rc integer;
  declare status integer;
  declare append smallint;
  declare maxrc, comptype, sysabcode, userabcode integer default 0;
  declare message varchar(1331);
  declare output clob ccsid unicode default '';
  
  set append = case when from is not null then 0 else 1 end;
  
  delete from SYSIBM.JOB_JCL;
  insert into SYSIBM.JOB_JCL(rownum, stmt)
  select rownum
       , text
   from xmltable('tokenize(., "[\r\n]{1,2}")'
                 passing xmltext(jcl)
                 columns rownum for ordinality, 
                         text   char(80) path 'replace(., "\\\\", "//")');
  call admin_job_submit(null, null, jobid, rc, message);
  repeat
    call admin_job_query(null, null, jobid, status, maxrc, comptype, sysabcode, userabcode, rc, message);
    if status in (1, 2) then
      -- Job in input or execution. Wait 1 second.
      call admin_command_unix(null, null, '/bin/sleep 1', null, rc, message);
    end if;
  until status not in (1, 2) end repeat;
  if status = 3 then
    -- Job finished and has output to be printed or retrieved
    call admin_job_fetch(null, null, jobid, rc, message);
    for select translate(text, x'4040404040', x'0607080A1F') as text 
          from sysibm.jes_sysout
    do
      if from is not null and posstr(text, from) > 0 then 
        set append = 1;
      end if;
      if from is not null and posstr(text, to) > 0 then 
        set append = 0;
      end if;
      if append = 1 then
        set output = output concat text concat x'0a';
      end if;
    end for;
  end if;
  return output;
end
#

drop function submit(jcl clob ccsid unicode)#

create function submit(jcl clob ccsid unicode)
  returns clob
  external action
  modifies sql data
  called on null input
begin
  return submit(jcl, cast(null as varchar(80)), cast(null as varchar(80)));
end
#

with job(jcl) as (
select '
//TEST JOB ,NOTIFY=&SYSUID
//DISPL  EXEC PGM=IEFBR14'
  from sysibm.sysdummyu
)
select submit(jcl) as sysout
  from job
#

