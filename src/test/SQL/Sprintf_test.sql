-- =============================================================================
-- Test Cases for SPRINTF Functions
-- =============================================================================
-- This file contains demonstration and test queries for the SPRINTF functions
-- defined in src/main/java/Sprintf.sql
--
-- Functions tested:
-- - SPRINTF(format, packed_data): Format with default locale
-- - SPRINTF(locale, format, packed_data): Format with specific locale
-- - SSCANF(format, data): Parse formatted data
-- =============================================================================

with p(p) as (
 select pack(ccsid 1208, 
             current timestamp
            ) from sysibm.sysdummyu
)
select sprintf('it', '%1$tB', p) as Result from p;

select sprintf('de', '%-20s %-20s: %ta, %<td.%<tm.%<tY: %,09.2f', 
               pack(ccsid 1208, lastname, firstnme, birthdate, salary))
  from dsn81310.emp;
  
select    char(lastname, 20)
       || ' ' 
       || char(firstnme, 20) 
       || ': '
       || decode(dayofweek_iso(birthdate), 1, 'Mon', 2, 'Tue', 3, 'Wed', 4, 'Thu', 5, 'Fri', 6, 'Sat', 7, 'Sun')
       || ', ' 
       || varchar_format(birthdate, 'DD.MM.YYYY')
       || ': '
       || varchar_format(salary, '000000.00')
  from dsn81310.emp;

-- Made with Bob
