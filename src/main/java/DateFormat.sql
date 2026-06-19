--==============================================================================
-- DateFormat.sql - FORMATTIMESTAMP User-Defined Functions
--==============================================================================
-- Purpose: Format TIMESTAMP values using Java DateTimeFormatter patterns
--
-- Functions:
--   FORMATTIMESTAMP(timestamp, format)
--     - Formats timestamp using specified pattern with default locale
--
--   FORMATTIMESTAMP(timestamp, format, locale)
--     - Formats timestamp using specified pattern and locale (e.g., 'de-DE')
--
-- Format Pattern Examples:
--   'EEEE, d MMM yyyy HH:mm:ss'  -> Wednesday, 11 Jun 2026 12:32:17
--   'yyyy-MM-dd HH:mm:ss'        -> 2026-06-11 12:32:17
--   'dd/MM/yyyy'                 -> 11/06/2026
--
-- Locale Examples: 'en-US', 'de-DE', 'ja-JP', 'fr-FR'
--
-- Note: Apostrophes in format strings must be doubled for SQL and Java
--       Example: '''It''''s ''H ''o''''clock''' for "It's 12 o'clock"
--==============================================================================

 set current schema = 'SYSFUN';
 drop function FORMATTIMESTAMP(ts timestamp, format varchar(32704)) ; 
 create function FORMATTIMESTAMP(ts timestamp, format varchar(32704)) 
 returns varchar(32704)
 external name 'ADCDMST.ROUTINES:com.ibm.db2.date.Date.format2'
 language java 
 parameter style java 
 no external action 
 allow parallel 
 wlm environment DBDGENVJ 
 asutime no limit 
 not secured 
 deterministic;
 
 drop function FORMATTIMESTAMP(ts timestamp, format varchar(32704), locale varchar(128))  ; 
 create function FORMATTIMESTAMP(ts timestamp, format varchar(32704), locale varchar(128)) 
 returns varchar(32704)
 external name 'ADCDMST.ROUTINES:com.ibm.db2.date.Date.format3'
 language java 
 parameter style java 
 no external action 
 allow parallel 
 wlm environment DBDGENVJ
 asutime no limit 
 not secured 
 deterministic;

-- Made with Bob
