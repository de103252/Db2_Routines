-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

-----------------------------------------------------------------------
-- GET_SYSTEM_SYMBOLS
-----------------------------------------------------------------------
-- Returns z/OS system symbols as a table.
-- System symbols are substitution variables maintained by z/OS
-- that are available to JCL and other system components.
--
-- Common symbols include:
--   &SYSNAME  - System name
--   &SYSPLEX  - Sysplex name  
--   &SYSCLONE - System clone identifier
--   &LPARNAME - LPAR name
--   &JOBNAME  - Job name (when in batch)
--   &SYSUID   - User ID
--
-- Prerequisites:
--   1. Compile getsyms.cbl and place load module in WLM STEPLIB
--   2. WLM environment must have authority to call ASASYMBM service
--
-- Installation:
--   Replace 'DBCGENVG' with your WLM environment name
--   Replace 'SYSFUN' with your desired schema
-----------------------------------------------------------------------

DROP FUNCTION SYSFUN.GET_SYSTEM_SYMBOLS()#

CREATE FUNCTION SYSFUN.GET_SYSTEM_SYMBOLS()
RETURNS TABLE(SYMBOL  VARCHAR(8),
              VALUE   VARCHAR(256))
LANGUAGE COBOL
PARAMETER STYLE SQL
PARAMETER CCSID EBCDIC
SCRATCHPAD 100
SECURITY USER
EXTERNAL NAME GETSYMS
PROGRAM TYPE MAIN
DISALLOW PARALLEL
NO EXTERNAL ACTION
DETERMINISTIC
CARDINALITY 50
WLM ENVIRONMENT DBCGENVG
STAY RESIDENT YES
ASUTIME NO LIMIT
FENCED
#

-----------------------------------------------------------------------
-- Test
-----------------------------------------------------------------------

-- List all system symbols
SELECT SYMBOL, VALUE
  FROM TABLE(SYSFUN.GET_SYSTEM_SYMBOLS())
 ORDER BY SYMBOL
#

-- Get specific symbol value
SELECT VALUE
  FROM TABLE(SYSFUN.GET_SYSTEM_SYMBOLS())
 WHERE SYMBOL = '&SYSNAME'
#

-- Check if running in a sysplex
SELECT CASE 
         WHEN VALUE IS NOT NULL AND VALUE <> '' 
         THEN 'Running in sysplex: ' || VALUE
         ELSE 'Not in a sysplex'
       END AS SYSPLEX_STATUS
  FROM TABLE(SYSFUN.GET_SYSTEM_SYMBOLS())
 WHERE SYMBOL = '&SYSPLEX'
#

-- Get system identification information
SELECT SYMBOL, VALUE
  FROM TABLE(SYSFUN.GET_SYSTEM_SYMBOLS())
 WHERE SYMBOL IN ('&SYSNAME', '&SYSPLEX', '&SYSCLONE', '&LPARNAME')
 ORDER BY SYMBOL
#

-- Use in JCL generation
WITH SYMS AS (
  SELECT SYMBOL, VALUE
    FROM TABLE(SYSFUN.GET_SYSTEM_SYMBOLS())
)
SELECT '//JOBNAME  JOB (ACCT),''USER'',' ||
       'NOTIFY=' || (SELECT VALUE FROM SYMS WHERE SYMBOL = '&SYSUID') ||
       ',REGION=0M' AS JCL_LINE
  FROM SYSIBM.SYSDUMMYU
UNION ALL
SELECT '//STEP1    EXEC PGM=IEFBR14'
  FROM SYSIBM.SYSDUMMYU
UNION ALL  
SELECT '//*        RUNNING ON SYSTEM: ' || 
       (SELECT VALUE FROM SYMS WHERE SYMBOL = '&SYSNAME')
  FROM SYSIBM.SYSDUMMYU
#

-- Following comment lines tell Data Studio resp. SPUFI
-- to use ; as statement terminator
--
--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

-- Made with Bob
