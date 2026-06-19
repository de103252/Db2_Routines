-- =====================================================================
-- JCL SUBMISSION AND OUTPUT RETRIEVAL FUNCTION
-- =====================================================================
-- Submit JCL job, wait for completion, and return job output.
--
-- Features:
-- - Submits JCL via ADMIN_JOB_SUBMIT stored procedure
-- - Waits for job completion using ADMIN_JOB_QUERY
-- - Retrieves complete job output (SYSOUT)
-- - Returns output as CLOB for large result sets
-- - Handles job status and completion codes
--
-- Parameters:
-- - jcl: JCL stream as CLOB (CCSID UNICODE)
--
-- Returns:
-- - Complete job output as CLOB including all SYSOUT datasets
--
-- Usage Examples:
-- - Submit job: SELECT submit('//MYJOB JOB ...\n//STEP1 EXEC PGM=IEFBR14') FROM SYSIBM.SYSDUMMYU
-- - Store output: INSERT INTO RESULTS SELECT submit(:jcl_text) FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

create function submit(jcl clob ccsid unicode)
  returns clob
  external action
  modifies sql data
  called on null input
begin
  declare jobid  char(8);
  declare rc     integer;
  declare status integer;
  declare append smallint;
  declare maxrc, comptype, sysabcode, userabcode integer default 0;
  declare message varchar(1331);
  declare output  clob ccsid unicode default '';

  -- Split the JCL text into lines and insert these into the
  -- SYSIBM.JOB_JCL temporary table. Then call ADMIN_JOB_SUBMIT.
  delete from SYSIBM.JOB_JCL;
  insert into SYSIBM.JOB_JCL(rownum, stmt)
  select rownum
       , text
   from xmltable('tokenize(., "[\r\n]{1,2}")'
                 passing xmltext(jcl)
                 columns rownum for ordinality, 
                         text   char(80) path '.');
  call admin_job_submit(null, null, jobid, rc, message);
  delete from SYSIBM.JOB_JCL;

  if rc > 4 then
    signal sqlstate '70900' 
      set message_text = 'ADMIN_JOB_SUBMIT failed: ' || message;
  end if;
  
  -- Wait for job termination.
  repeat
    call admin_job_query(null, null, 
                         jobid, status, maxrc, 
                         comptype, sysabcode, userabcode,
                         rc, message);
    if rc > 4 then
      signal sqlstate '70901' 
        set message_text = 'ADMIN_JOB_QUERY failed: ' || message;
    end if;
    if status in (1, 2) then
      -- Job in input or execution. Wait 1 second.
      call admin_command_unix(null, null,
                              '/bin/sleep 1', 
                              null, rc, message);
      if rc > 4 then
        signal sqlstate '70902' 
          set message_text = 'ADMIN_COMMAND_UNIX failed: ' || message;
      end if;
    end if;
  until status not in (1, 2) end repeat;
  if status <> 3 then
    signal sqlstate '70903' 
      set message_text = 'Unexpected job status: ' || status;
  end if;
  
  -- At this point, the job has finished. Retrieve the output,
  -- replacing some EBCDIC control characters with spaces,
  -- and collect it. 
  call admin_job_fetch(null, null, jobid, rc, message);
  for select translate(text, x'4040404040', x'0607080A1F') as text 
        from sysibm.jes_sysout
  do
    set output = output concat text concat x'0a';
  end for;
  
  return output;
end
#

-- Submit JCL, wait for job termination, and return the job output
-- as a table.
drop function sysfun.submit_t(jcl clob ccsid unicode)#
create function sysfun.submit_t(jcl clob ccsid unicode)
  returns table(rownum integer, text varchar(4096))
  --external action
  --modifies sql data
  called on null input
begin atomic
  return 
    select rownum, text
      from xmltable('tokenize(., "[\r\n]{1,2}")'
                    passing xmltext(submit(jcl))
                    columns rownum for ordinality, 
                            text   varchar(4096) path '.');
end#


comment on function sysfun.submit(jcl clob ccsid unicode)
is 'Submit a job stream and return the job output'
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

select *
  from table(submit_t('
//TEST JOB ,NOTIFY=&SYSUID
//DISPL  EXEC PGM=IEFBR14'))
#

