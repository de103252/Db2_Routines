-- =====================================================================
-- TEST SUITE FOR UPDATE SYSTEM PARAMETERS FUNCTION
-- =====================================================================
-- Tests for the update_sysparm() function that updates Db2 system
-- parameters (ZPARMS) dynamically via SET SYSPARM command.
--
-- Test Coverage:
-- - Invalid parameter format (missing macro)
-- - Multiple parameter updates
-- - Single parameter update
-- - SYSPARM_SETTINGS table verification
-- - Utility output retrieval
-- =====================================================================

-----------------------------------------------------------------------
-- Test 1: Invalid parameter format (should fail)
-----------------------------------------------------------------------

select update_sysparm('a.CTHREAD=b') from sysibm.sysdummyu;
select db2util.utility_output from sysibm.sysdummyu;

-----------------------------------------------------------------------
-- Test 2: Multiple parameter updates
-----------------------------------------------------------------------

select update_sysparm('', '',
  'DSN6SYSP.CTHREAD=666,' ||
  'DSN6SPRM.TABLE_COL_NAME_EXPANSION=OFF'
) from sysibm.sysdummyu;
select db2util.utility_output from sysibm.sysdummyu;

-----------------------------------------------------------------------
-- Test 3: Single parameter update
-----------------------------------------------------------------------

select update_sysparm('', '',
  'DSN6SPRM.TABLE_COL_NAME_EXPANSION=OFF'
) from sysibm.sysdummyu;
select db2util.utility_output from sysibm.sysdummyu;
