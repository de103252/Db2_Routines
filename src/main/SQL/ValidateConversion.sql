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
