-- =====================================================================
-- TEST SUITE FOR TRY CONVERSION FUNCTIONS (INTEGER TYPES)
-- =====================================================================
-- Tests for the try_integer(), try_smallint(), and try_bigint() functions
-- that safely convert strings to integer types.
--
-- Test Coverage:
-- - Basic integer conversion
-- - Conversion with leading/trailing blanks
-- - Invalid string handling (returns NULL)
-- - Comprehensive test matrix with expected results
-- - Edge cases (min/max values, overflow)
-- =====================================================================

--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

-----------------------------------------------------------------------
-- Test 1: Basic conversions with blanks and invalid input
-----------------------------------------------------------------------

select try_integer('42')        answer1,
        try_integer('  42  ')   answer2,
        try_integer('fortytwo') answer3
  from sysibm.sysdummy1;
  
-----------------------------------------------------------------------
-- Test 2: Comprehensive test matrix
-----------------------------------------------------------------------

with
u(null_s, null_i, null_b) as (
  select cast(null as smallint)
       , cast(null as integer)
       , cast(null as bigint)
    from sysibm.sysdummyu
),
values(v, es, ei, eb) as (
            select '',                       null_s, null_i, null_b               from u
  union all select '  42   ',                42,     42,     42                   from u
  union all select '  42.42 ',               42,     42,     42                   from u
  union all select 'aa42bb',                 null_s, null_i, null_b               from u
  union all select '  42a',                  null_s, null_i, null_b               from u
  union all select '  42a',                  null_s, null_i, null_b               from u
  union all select '  42a',                  null_s, null_i, null_b               from u
  union all select '  -9223372036854775808', null_s, null_i, -9223372036854775808 from u
  union all select '  9223372036854775807',  null_s, null_i, 9223372036854775807  from u
  union all select '  9223372036854775808 ', null_s, null_i, null_b               from u
  union all select '  -9223372036854775809', null_s, null_i, null_b               from u
),
results as (
select v.*, try_smallint(v) as, try_integer(v) ai, try_bigint(v) ab
  from values v
)
select *
  from results
 where as is distinct from es
    or ai is distinct from ei
    or ab is distinct from eb
    or 1 = 1 -- Remove to see wrong results only
;

-- Made with Bob
