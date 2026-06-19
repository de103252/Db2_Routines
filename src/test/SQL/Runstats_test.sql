-- =====================================================================
-- TEST SUITE FOR RUNSTATS UTILITY EXECUTION FUNCTION
-- =====================================================================
-- Tests for the runstats() function that executes RUNSTATS utility
-- against tables or tablespaces with pattern matching.
--
-- Test Coverage:
-- - Pattern-based table selection (DSN81310.EMP%)
-- - Utility output retrieval
-- =====================================================================

--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

-----------------------------------------------------------------------
-- Test 1: Execute RUNSTATS on tables matching pattern
-----------------------------------------------------------------------

select runstats('TABLES', 'DSN81310', 'EMP%', '')
  from sysibm.sysdummyu
;

-----------------------------------------------------------------------
-- Test 2: Retrieve utility output
-----------------------------------------------------------------------

select db2util.utility_output
  from sysibm.sysdummyu
;

-- Made with Bob
