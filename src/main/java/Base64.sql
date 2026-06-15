-- =============================================================================
-- Base64 Encoding and Decoding Functions
-- =============================================================================
-- Author: Uli Seelbach
--
-- Overview:
-- This module provides Base64 encoding and decoding functions for Db2 for z/OS.
-- Base64 is a binary-to-text encoding scheme that represents binary data in an
-- ASCII string format. These functions enable conversion between binary data
-- (BLOB/VARBINARY) and Base64-encoded text (CLOB/VARCHAR).
--
-- Implementation:
-- All functions are implemented as Java external functions using the
-- com.ibm.db2.base64.Base64 class in the ADCDMST.ROUTINES JAR file.
--
-- Size Relationships:
-- Base64 encoding increases data size by approximately 33%:
-- - 3 bytes of binary data → 4 characters of Base64 text
-- - VARBINARY(24528) → VARCHAR(32704) (24528 × 4/3 = 32704)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Function: base64decode (CLOB to BLOB)
-- -----------------------------------------------------------------------------
-- Description:
--   Decodes a Base64-encoded CLOB string into binary BLOB data.
--
-- Syntax:
--   base64decode(data clob(64m) ccsid unicode) returns blob(64m)
--
-- Parameters:
--   data - Base64-encoded string as CLOB(64M) with Unicode CCSID
--
-- Returns:
--   BLOB(64M) - Decoded binary data
--   NULL if input is NULL
--
-- Example:
--   select base64decode(clob('VWxpIFNlZWxiYWNo')) from sysibm.sysdummyu;
-- -----------------------------------------------------------------------------

drop function sysfun.base64decode(data clob(64M) ccsid unicode);
 
create function sysfun.base64decode(data clob(64m) ccsid unicode) 
  returns blob(64M)
  specific base64decode_clob2blob
  returns null on null input
  external name 
    'ADCDMST.ROUTINES:com.ibm.db2.base64.Base64.decode'
  language java 
  parameter style java 
  no external action 
  allow parallel 
  wlm environment DBDGENVJ 
  asutime no limit 
  deterministic;

-- -----------------------------------------------------------------------------
-- Function: base64decode (VARCHAR to VARBINARY)
-- -----------------------------------------------------------------------------
-- Description:
--   Decodes a Base64-encoded VARCHAR string into binary VARBINARY data.
--
-- Syntax:
--   base64decode(data varchar(32704) ccsid unicode) returns varbinary(24528)
--
-- Parameters:
--   data - Base64-encoded string as VARCHAR(32704) with Unicode CCSID
--
-- Returns:
--   VARBINARY(24528) - Decoded binary data (approximately 3/4 of input length)
--   NULL if input is NULL
--
-- -----------------------------------------------------------------------------

drop function sysfun.base64decode(data varchar(32704) ccsid unicode);
create function sysfun.base64decode(data varchar(32704) ccsid unicode) 
  returns VARBINARY(24528)
  specific base64decode_char2binary
  returns null on null input
  external name 
    'ADCDMST.ROUTINES:com.ibm.db2.base64.Base64.decode'
  language java 
  parameter style java 
  no external action 
  allow parallel 
  wlm environment DBDGENVJ 
  asutime no limit 
  deterministic;

-- -----------------------------------------------------------------------------
-- Function: base64encode (BLOB to CLOB)
-- -----------------------------------------------------------------------------
-- Description:
--   Encodes binary BLOB data into a Base64-encoded CLOB string.
--
-- Syntax:
--   base64encode(data blob(64m)) returns clob(64m) ccsid unicode
--
-- Parameters:
--   data - Binary data as BLOB(64M)
--
-- Returns:
--   CLOB(64M) - Base64-encoded string with Unicode CCSID
--   NULL if input is NULL
--
-- Characteristics:
--   - Specific name: base64encode_blob2clob
--   - Deterministic: Yes
--   - External action: No
--   - SQL access: Reads SQL data
--   - Parallel execution: Allowed
--   - WLM environment: DBDGENVJ
--   - Execution mode: Fenced
--
-- Example:
--   select base64encode(cast('Uli Seelbach' as blob)) from sysibm.sysdummyu;
--   -- Returns: VWxpIFNlZWxiYWNo
--
--   select base64encode(cast(null as blob)) from sysibm.sysdummyu;
--   -- Returns: NULL
-- -----------------------------------------------------------------------------
  
drop function sysfun.base64encode (data blob(64m));
create function sysfun.base64encode (data blob(64m))
  returns clob(64m) ccsid unicode
  specific base64encode_blob2clob
  returns null on null input
  external name 'ADCDMST.ROUTINES:com.ibm.db2.base64.Base64.encode'
  language java
  parameter style java
  deterministic
  fenced
  reads sql data
  no external action
  allow parallel
  wlm environment DBDGENVJ
  asutime no limit
  ;

-- -----------------------------------------------------------------------------
-- Function: base64encode (VARBINARY to VARCHAR)
-- -----------------------------------------------------------------------------
-- Description:
--   Encodes binary VARBINARY data into a Base64-encoded VARCHAR string.
--
-- Syntax:
--   base64encode(data varbinary(24528)) returns varchar(32704) ccsid unicode
--
-- Parameters:
--   data - Binary data as VARBINARY(24528)
--
-- Returns:
--   VARCHAR(32704) - Base64-encoded string with Unicode CCSID
--                    (approximately 4/3 of input length)
--   NULL if input is NULL
--
-- -----------------------------------------------------------------------------
  
drop function sysfun.base64encode (data varbinary(24528));
create function sysfun.base64encode (data varbinary(24528))
  returns varchar(32704) ccsid unicode
  specific base64encode_binary2char
  returns null on null input
  external name 'ADCDMST.ROUTINES:com.ibm.db2.base64.Base64.encode'
  language java
  parameter style java
  deterministic
  fenced
  reads sql data
  no external action
  allow parallel
  wlm environment DBDGENVJ
;

-- =============================================================================
-- Usage Examples
-- =============================================================================

-- Example 1: Basic encoding - encode text to Base64
SELECT base64encode(cast('Uli Seelbach' as blob)) from sysibm.sysdummyu;

-- Example 2: Encoding NULL values
SELECT base64encode(cast(null as blob)) from sysibm.sysdummyu;

-- Example 3: Basic decoding - decode Base64 back to binary
SELECT base64decode('VWxpIFNlZWxiYWNo') from sysibm.sysdummyu;

-- SELECT interpret(base64decode('VWxpIFNlZWxiYWNo') as char(12)) from sysibm.sysdummyu;

-- Example 4: Encoding multiple concatenated values
-- This example demonstrates encoding a list of table names
with t100 as (
  select name from sysibm.systables fetch first 100 rows only
),
t as (
  select listagg(name) names from t100
)
select length(names), length(base64encode(varbinary(names))) from t

-- =============================================================================
-- Notes:
-- - All functions return NULL when given NULL input
-- - The functions are deterministic and can be used in parallel execution
-- - Unicode CCSID is required for character input/output parameters
-- - The WLM environment DBDGENVJ must be configured for Java execution
--
-- See Also:
-- - Java implementation: com/ibm/db2/base64/Base64.java
-- =============================================================================
