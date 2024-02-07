-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

/*
Tests whether a given character string can be converted
to the specified built-in data type.
If the string can be successfully converted, returns 1;
otherwise, returns 0.
If the string is NULL, returns 1.
If target_type does not specify a valid built-in type name, 
returns an error.
*/

drop function sysfun.validate_conversion(src varchar(32704), 
                                  target_type varchar(64))#

create function sysfun.validate_conversion(src varchar(32704), 
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
  return d;
end
#

with
d(d) as (
  select 1 from sysibm.sysdummyu
),
tests(value, type, expected_result) as (
            select '42', 'integer',  1 from d 
  union all select '42', 'smallint', 1 from d 
  union all select '42', 'bigint',   1 from d 
  union all select '42', 'smallint', 1 from d
  union all select '  42  ', 'smallint', 1 from d
  union all select 'junk', 'integer', 0 from d
  union all select '2147483647', 'integer', 1 from d
  union all select '2147483648', 'integer', 0 from d
  union all select '2024-01-09', 'date', 1 from d
  union all select '2024-02-30', 'date', 0 from d
  union all select '2024.98765', 'decfloat', 1 from d
),
results(value, type, expected_result, actual_result) as (
  select tests.*, validate_conversion(value, type)
    from tests
)
select *
  from results
 where expected_result <> actual_result
#


select validate_conversion('2024-01-25', 'date') as result
  from sysibm.sysdummyu#
  
select validate_conversion('2024-01-25 16:15:14.12345+01:00', 'timestamp(0) with timezone') as result
  from sysibm.sysdummyu#
  
select current timestamp with timezone from sysibm.sysdummyu#

select validate_conversion(cast(null as char), 'integer') as result
  from sysibm.sysdummyu#
  
select validate_conversion(cast(null as char), 'bullshit') as result
  from sysibm.sysdummyu#