-- =====================================================================
-- TEST SUITE FOR GENERATE SERIES TABLE FUNCTION
-- =====================================================================
-- Tests for the generate_series() table functions that generate
-- sequences of integer values.
--
-- Test Coverage:
-- - Basic ascending sequence (default step of 1)
-- - Custom step increment
-- - Descending sequence (negative step)
-- - Date arithmetic with series
-- - Random number generation with series
-- =====================================================================

-----------------------------------------------------------------------
-- Test 1: Basic ascending sequence (1 to 5)
-----------------------------------------------------------------------

select value
  from table(generate_series(1, 5));
  
-----------------------------------------------------------------------
-- Test 2: Custom step increment (1 to 9, step 3)
-----------------------------------------------------------------------

select value
  from table(generate_series(1, 9, 3));

-----------------------------------------------------------------------
-- Test 3: Descending sequence (countdown from 10 to 0)
-----------------------------------------------------------------------

select value as countdown
  from table(generate_series(10, 0, -1));
  
-----------------------------------------------------------------------
-- Test 4: Date arithmetic - Next 4 Saturdays
-----------------------------------------------------------------------

-- Next 4 Saturdays
select current date + (6 - dayofweek_iso(current date) + value) days as Saturday
  from table(generate_series(0, 3*7, 7));
  
-----------------------------------------------------------------------
-- Test 5: Random number generation
-----------------------------------------------------------------------

-- 42 random integers in the range [0, 100)
select integer(rand() * 100)
  from table(generate_series(1, 42));

-- Made with Bob
