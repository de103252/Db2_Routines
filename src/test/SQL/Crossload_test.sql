-- =====================================================================
-- TEST SUITE FOR CROSS-LOAD FUNCTIONS
-- =====================================================================
-- Tests for the crossload functions that copy table contents between
-- schemas and tables using the Db2 LOAD utility.
--
-- Test Coverage:
-- - Custom SELECT statement with explicit temp space
-- - Schema-wide copy of all matching tables
-- - Single table copy with automatic column mapping
-- =====================================================================

-----------------------------------------------------------------------
-- Test 1: Custom SELECT with explicit temp space
-----------------------------------------------------------------------

create table emp like dsn81310.emp in database testuts;

select crossload('select * from dsn81310.emp', 
                 current sqlid, 'EMP',
                 100) as rc
  from sysibm.sysdummyu
;

select db2util.utility_output
  from sysibm.sysdummyu
;

select * from emp
;

-----------------------------------------------------------------------
-- Test 2: Schema-wide copy
-----------------------------------------------------------------------

select crossload('DSN81310', current sqlid) as rc
     , utility_output
  from sysibm.sysdummyu
;

select utility_output
  from sysibm.sysdummyu
;

-----------------------------------------------------------------------
-- Test 3: Single table copy with automatic column mapping
-----------------------------------------------------------------------

select crossload('DSN81310', 'EMP', current sqlid, 'EMP') as rc
     , utility_output
  from sysibm.sysdummyu
;