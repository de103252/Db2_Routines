-- =====================================================================
-- READ GENERIC FILE TABLE FUNCTION
-- =====================================================================
-- Read fixed-format binary files from z/OS datasets into table format.
--
-- Features:
-- - Returns generic table with user-defined column structure
-- - Reads z/OS sequential datasets or PDS members
-- - Supports various data types
--   (CHAR, INTEGER, BIGINT, DATE, TIME, DECIMAL, VARBINARY)
--
-- Parameters:
-- - FILENAME: Dataset name (e.g., 'ADCDMST.FLATFILE.BIN')
-- - FLAGS: Processing flags (typically 0)
--
-- Usage Example:
-- - Read binary file: 
--   SELECT * FROM TABLE(READ_GENERIC_FILE('ADCDMST.FLATFILE.BIN', 0)) T (
--     id CHAR(8), name CHAR(35), int64 BIGINT, int32 INTEGER, 
--     int16 SMALLINT, ddd DATE, tm TIME, salary DECIMAL(9,2), rst VARBINARY(80)
--   )
-- =====================================================================

set current schema = 'SYSFUN';

drop function read_generic_file(filename varchar(54), flags integer);

create function read_generic_file(filename varchar(54), flags integer)
  returns generic table
    specific read_generic_file
    language c
    security user
    external name rdgenfil
    parameter style db2sql
    parameter ccsid ebcdic
    parameter varchar structure
    final call
    fenced
    not deterministic
    external action
    disallow parallel
    scratchpad 64
    wlm environment dbdgenv
    stay resident yes
    run options 'POSIX(ON),XPLINK(ON)'
    -- for debug:
    --   'POSIX(ON),XPLINK(ON),TEST(,,,TCPIP&10.1.1.1%8001:*)'
    cardinality 100000
 ;

SELECT *
  FROM TABLE(READ_GENERIC_FILE('ADCDMST.FLATFILE.BIN', 0)) T (
         id     char(8)          -- col  1
       , name   char(35)         -- col  9
       , int64  bigint           -- col 44
       , int32  INTEGER          -- col 52
       , int16  SMALLINT         -- col 56
       , ddd    date             -- col 58
       , tm     time             -- col 66
       , salary decimal(9, 2)    -- col 70
       , rst    varbinary(80)    -- col 75
        )
;
