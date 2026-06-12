set current schema = 'SYSFUN';

DROP FUNCTION READ_GENERIC_FILE(FILENAME VARCHAR(54), FLAGS INTEGER);

CREATE FUNCTION READ_GENERIC_FILE(FILENAME VARCHAR(54), FLAGS INTEGER)
  RETURNS GENERIC TABLE
    SPECIFIC READ_GENERIC_FILE
    LANGUAGE C
    SECURITY USER
    EXTERNAL NAME RDGENFIL
    PARAMETER STYLE DB2SQL
    PARAMETER CCSID EBCDIC
    PARAMETER VARCHAR STRUCTURE
    FINAL CALL
    FENCED
    NOT DETERMINISTIC
    EXTERNAL ACTION
    DISALLOW PARALLEL
    SCRATCHPAD 64
    WLM ENVIRONMENT DBDGENV
    STAY RESIDENT YES
    RUN OPTIONS 'POSIX(ON),XPLINK(ON)'
    -- for debug:
    --   'POSIX(ON),XPLINK(ON),TEST(,,,TCPIP&10.1.1.1%8001:*)'
    CARDINALITY 100000
 ;

SELECT *
  FROM TABLE(READ_GENERIC_FILE('ADCDMST.FLATFILE.BIN', 0)) T (
          id     char(8)         -- col 1
       , name   char(35)         -- col 9
       , int64  bigint           -- col 44
       , int32  INTEGER          -- col 52
       , int16  SMALLINT         -- col 56
       , ddd    date             -- col 58
       , tm     time             -- col 66
       , salary decimal(9, 2)    -- col 70
       , rst    varbinary(80)    -- col 75
        )
;
