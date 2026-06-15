-- =============================================================================
-- GZip Compression and Decompression Functions
-- =============================================================================
-- Author: Uli Seelbach
--
-- Overview:
-- This module provides GZIP compression and decompression functions for
-- Db2 for z/OS. The functions operate on BLOB data and use Java's built-in
-- GZIP stream support to compress and decompress binary content.
--
-- Implementation:
-- All functions are implemented as Java external functions using the
-- com.ibm.db2.gzip.GZip class in the ADCDMST.ROUTINES JAR file.
--
-- Notes:
-- - Input and output are BLOB(10M)
-- - The Java implementation validates NULL input and GZIP format
-- - Empty input handling differs by function:
--   - GZIP returns an empty BLOB for empty input
--   - GUNZIP raises an error for empty input
-- =============================================================================

set current schema = 'SYSFUN';

-- -----------------------------------------------------------------------------
-- Function: GZIP
-- -----------------------------------------------------------------------------
-- Description:
--   Compresses input BLOB data using the GZIP algorithm and returns the
--   compressed result as a BLOB value.
--
-- Syntax:
--   GZIP(input_blob) returns blob(10m)
--
-- Parameters:
--   input - BLOB(10M) containing uncompressed binary data
--
-- Returns:
--   BLOB(10M) containing the GZIP-compressed output
--
-- Characteristics:
--   - Specific name: GZIP_BLOB
--   - Deterministic: Yes
--   - Language: Java
--   - Parameter style: Java
--   - SQL access: No SQL
--   - External action: No
--   - WLM environment: DBDGENVJ
--   - Execution mode: Fenced
--
-- Example:
--   select gzip(cast('Hello World' as blob(10m))) from sysibm.sysdummyu;
-- -----------------------------------------------------------------------------

drop function GZIP(blob(10m));

create function GZIP(input blob(10m))
  returns blob(10m)
  specific GZIP_BLOB
  external name 'ADCDMST.ROUTINES:com.ibm.db2.gzip.GZip.gzip'
  language java
  parameter style java
  deterministic
  fenced
  no external action
  allow parallel
  wlm environment DBDGENVJ
  asutime no limit
  ;

-- -----------------------------------------------------------------------------
-- Function: GUNZIP
-- -----------------------------------------------------------------------------
-- Description:
--   Decompresses GZIP-compressed input BLOB data and returns the original
--   uncompressed content as a BLOB value.
--
-- Syntax:
--   GUNZIP(input_blob) returns blob(10m)
--
-- Parameters:
--   input - BLOB(10M) containing GZIP-compressed binary data
--
-- Returns:
--   BLOB(10M) containing the decompressed output
--
-- Characteristics:
--   - Specific name: GUNZIP_BLOB
--   - Deterministic: Yes
--   - Language: Java
--   - Parameter style: Java
--   - SQL access: No SQL
--   - External action: No
--   - WLM environment: DBDGENVJ
--   - Execution mode: Fenced
--
-- Example:
--   select gunzip(gzip(cast('Hello World' as blob(10m)))) from sysibm.sysdummyu;
-- -----------------------------------------------------------------------------

drop function GUNZIP(blob(10m));

create function GUNZIP(input blob(10m))
  returns blob(10m)
  specific GUNZIP_BLOB
  external name 'ADCDMST.ROUTINES:com.ibm.db2.gzip.GZip.gunzip'
  language java
  parameter style java
  deterministic
  fenced
  no external action
  allow parallel
  wlm environment DBDGENVJ
  asutime no limit
  ;

-- =============================================================================
-- Usage Notes
-- =============================================================================
-- - Both functions are implemented in Java and run in a Java WLM environment
-- - GUNZIP expects valid GZIP input and raises an error for invalid or empty data
-- - Maximum input size validation is enforced by the Java implementation
--
-- See Also:
-- - Java implementation: com/ibm/db2/gzip/GZip.java
-- =============================================================================

-- =============================================================================
-- Simple Test Calls
-- =============================================================================

-- Test 1: Compress a short text value and show original/compressed lengths
select length(cast('Hello World' as blob(10m))) as original_length,
       length(gzip(cast('Hello World' as blob(10m)))) as compressed_length
  from sysibm.sysdummyu;

-- Test 2: Round-trip compression and decompression
select gunzip(gzip(cast('Hello World' as blob(10m))))
  from sysibm.sysdummyu;

-- Test 3: Round-trip validation by checking decompressed length
select length(gunzip(gzip(cast('Hello World' as blob(10m))))) as roundtrip_length
  from sysibm.sysdummyu;
