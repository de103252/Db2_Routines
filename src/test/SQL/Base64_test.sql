-- =============================================================================
-- Test Cases for Base64 Encoding and Decoding Functions
-- =============================================================================
-- This file contains demonstration and test queries for the Base64 functions
-- defined in src/main/SQL/Base64.sql
--
-- Functions tested:
-- - BASE64ENCODE: Encodes binary data to Base64 format
-- - BASE64DECODE: Decodes Base64 format to binary data
-- =============================================================================

-- Example 1: Basic encoding - encode text to Base64
SELECT base64encode(cast('Uli Seelbach' as blob))
  from sysibm.sysdummyu;

-- Example 2: Encoding NULL values
SELECT base64encode(cast(null as blob))
  from sysibm.sysdummyu;

-- Example 3: Basic decoding - decode Base64 back to binary
SELECT base64decode('VWxpIFNlZWxiYWNo') 
  from sysibm.sysdummyu;

-- SELECT interpret(base64decode('VWxpIFNlZWxiYWNo') as char(12)) from sysibm.sysdummyu;

-- Example 4: Encoding multiple concatenated values
-- This example demonstrates encoding a list of table names
with 
t100 as (
  select name from sysibm.systables fetch first 100 rows only
),
t as (
  select listagg(name) names from t100
)
select length(names), length(base64encode(varbinary(names))) from t;
