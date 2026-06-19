-- =============================================================================
-- Test Cases for GZip Compression and Decompression Functions
-- =============================================================================
-- This file contains demonstration and test queries for the GZIP functions
-- defined in GZip.sql
--
-- Functions tested:
-- - GZIP: Compresses BLOB data using GZIP compression
-- - GUNZIP: Decompresses GZIP-compressed BLOB data
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

-- Made with Bob
