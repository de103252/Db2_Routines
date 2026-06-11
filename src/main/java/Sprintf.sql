--==============================================================================
-- Sprintf.sql - SPRINTF User-Defined Functions
--==============================================================================
-- Purpose: Format data using Java String.format() patterns with locale support
--
-- Functions:
--   SPRINTF(format, packed_data)
--     - Formats packed data using specified format string with default locale
--
--   SPRINTF(locale, format, packed_data)
--     - Formats packed data using specified format string and locale (e.g., 'de', 'en-US')
--
-- Format Pattern Examples:
--   '%s'                             -> String formatting
--   '%d'                             -> Integer formatting
--   '%,09.2f'                        -> Decimal with thousands separator: 000,123.45
--   '%1$tB'                          -> Month name from timestamp (locale-dependent)
--   '%ta, %<td.%<tm.%<tY'           -> Date formatting: Wed, 11.06.2026
--
-- Locale Examples: 'de', 'en-US', 'ja-JP', 'fr-FR', 'it'
--
-- Note: Data must be packed using PACK(CCSID 1208, ...) for UTF-8 encoding
--       The packed_data parameter contains multiple values in binary format
--       Use %< to reuse the previous argument in format string
--==============================================================================

set current schema = 'SYSFUN';

drop function SPRINTF(format varchar(32704), packed_data varbinary(32704)); 

create function SPRINTF(format varchar(32704), packed_data varbinary(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.sprintf.Sprintf.sprintf'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic; 

drop function SPRINTF(locale varchar(64), format varchar(32704), packed_data varbinary(32704)); 
create function SPRINTF(locale varchar(64), format varchar(32704), packed_data varbinary(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.sprintf.Sprintf.sprintf'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic; 

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
  
create function SSCANF(format varchar(32704), data varchar(32704)) 
returns varbinary(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.sprintf.Sprintf.sscanf'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic; 
