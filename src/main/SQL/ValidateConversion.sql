-- =====================================================================
-- VALIDATE CONVERSION FUNCTION
-- =====================================================================
-- Test if string can be converted to specified data type.
--
-- Features:
-- - Validates conversion to any built-in Db2 data type
-- - Returns 1 if conversion succeeds, 0 if it fails
-- - Returns 1 for NULL input (NULL is valid for any type)
-- - Deterministic with no external actions
-- - Uses dynamic SQL to test conversion
--
-- Parameters:
-- - src: Source string to test (VARCHAR(32704))
-- - target_type: Target data type name (VARCHAR(64))
--
-- Supported Types:
-- - INTEGER, SMALLINT, BIGINT, DECIMAL, NUMERIC, FLOAT, REAL, DOUBLE
-- - DATE, TIME, TIMESTAMP
-- - CHAR, VARCHAR, CLOB
-- - And all other built-in Db2 types
--
-- Usage Examples:
-- - Test integer: SELECT validate_conversion('42', 'INTEGER') FROM SYSIBM.SYSDUMMYU  -- Returns 1
-- - Test invalid: SELECT validate_conversion('abc', 'INTEGER') FROM SYSIBM.SYSDUMMYU  -- Returns 0
-- - Test date: SELECT validate_conversion('2024-12-25', 'DATE') FROM SYSIBM.SYSDUMMYU  -- Returns 1
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

drop function validate_conversion(src varchar(32704),
                                  target_type varchar(64))#

create function validate_conversion(src varchar(32704),
                                    target_type varchar(64))
  returns integer
  deterministic
  called on null input
  no external action
  reads sql data
begin
  declare sql varchar(32704);
  declare r integer;
  declare stmt statement;
  declare c cursor for stmt;

  -- Declare exit handlers that intercept conversion errors
  -- and return 0 instead.
    
  -- STRING ARGUMENT WAS NOT ACCEPTABLE
  declare exit handler for sqlstate '22018' return 0;
  -- DATE, TIME, OR TIMESTAMP VALUE IS INVALID
  declare exit handler for sqlstate '22007' return 0; 

/*
  -- The following handlers would catch nonexisting data type names
  -- or syntax errors, and handle them by returning 0.
  -- We prefer to not handle these errors but return them.
  
  -- UNDEFINED NAME
  declare exit handler for sqlstate '42704' return 0;
  -- ILLEGAL SYMBOL
  declare exit handler for sqlstate '42601' return 0;
  -- NULL‬‎ ‪IS‬‎ ‪NOT‬‎ ‪ALLOWED
  declare exit handler for sqlstate '22004' return 0; 
*/
  
  -- Prepare a CAST expression from source to target type.
  set sql = 'select case'
         || '         when cast(cast(? as varchar(32704))'
         || '                   as ' || target_type || ') is null '
         || '         then 1' 
         || '         else 1 '
         || '       end from sysibm.sysdummyu';
  prepare stmt from sql;
  open c using src;
  fetch c into r;
  close c;
  
  -- If we reach this point, no exit handler has been activated, 
  -- meaning that the type conversion was successful.
  return r;
end
#

-----------------------------------------------------------------------
-- Test
-----------------------------------------------------------------------

with
d(d) as (
  select 1 from sysibm.sysdummyu
),
tests(value, type, expected_result) as (
            select '42',         'integer',       1 from d 
  union all select '42',         'smallint',      1 from d 
  union all select '42',         'bigint',        1 from d 
  union all select '42',         'smallint',      1 from d 
  union all select '  42  ',     'smallint',      1 from d  -- leading and trailing blanks ok
  union all select 'junk',       'integer',       0 from d  -- complete junk not ok
  union all select '2147483647', 'integer',       1 from d  -- within range 
  union all select '2147483648', 'integer',       0 from d  -- not within range
  union all select '-2147483648', 'integer',      0 from d  -- within range
  union all select '2024-01-09', 'date',          1 from d 
  union all select '1.9.2024',   'date',          1 from d 
  union all select '2024-02-30', 'date',          0 from d  -- No February 30 
  union all select '29.2.2024',  'date',          1 from d  -- Leap year, European date format 
  union all select '29.2.2023',  'date',          0 from d  -- Not a leap year
  union all select '47.11',      'decimal(4, 2)', 1 from d  -- Precision and scale ok
  union all select '-47.11',     'decimal(4, 2)', 1 from d  -- Negative ok
  union all select '47.11',      'decimal(3, 2)', 0 from d  -- Insufficient precision 
  union all select '47.11',      'decimal(3, 1)', 1 from d  -- With truncation of scale, precision now ok 
  union all select '2024.98765', 'decfloat',      1 from d 
  union all select '2024-01-25 16:15:14.12345+01:00',
                   'timestamp(0) with timezone',  1 from d
  union all select cast(null as char), 'integer', 1 from d  -- Nulls ok                                  
),
results as (
  select row_number() over() as row
       , tests.*
       , validate_conversion(value, type) actual_result
    from tests
)
select *
  from results
 where expected_result <> actual_result
    OR 1 = 1 -- remove to see wrong results only
#

-- This is going to fail  
select validate_conversion(cast(null as char), 'bullshit') as result
  from sysibm.sysdummyu#
