-- =====================================================================
-- TEST SUITE FOR JCL SUBMISSION AND OUTPUT RETRIEVAL FUNCTION
-- =====================================================================
-- Tests for the submit() and submit_t() functions that submit JCL jobs,
-- wait for completion, and return job output.
--
-- Test Coverage:
-- - Basic JCL submission with CLOB output
-- - Table function variant returning rows
-- =====================================================================

-----------------------------------------------------------------------
-- Test 1: Submit JCL and return output as CLOB
-----------------------------------------------------------------------

with job(jcl) as (
select '
//TEST JOB ,NOTIFY=&SYSUID
//DISPL  EXEC PGM=IEFBR14'
  from sysibm.sysdummyu
)
select submit(jcl) as sysout
  from job
;

-----------------------------------------------------------------------
-- Test 2: Submit JCL and return output as table
-----------------------------------------------------------------------

select *
  from table(submit_t('
//TEST JOB ,NOTIFY=&SYSUID
//DISPL  EXEC PGM=IEFBR14'))
;