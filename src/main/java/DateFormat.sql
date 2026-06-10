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

select formattimestamp(current timestamp, 'EEEE, d MMM yyyy HH:mm:ss') 
 from sysibm.sysdummyu; 
 
select formattimestamp(current timestamp, 'EEEE, d MMM yyyy HH:mm:ss', 'de-DE') 
 from sysibm.sysdummyu;

with 
u(u) as (
  select * from sysibm.sysdummyu
),
locales(locale) as (
            select 'de-DE' from u
  union all select 'en-US' from u
  union all select 'hu-HU' from u
  union all select 'sv-SE' from u
  union all select 'ja-JP' from u
  union all select 'de-AT' from u
)
select locale,
       formattimestamp(current timestamp, 'EEEE, d MMMM yyyy HH:mm:ss', locale) now,
       formattimestamp(timestamp('2025-01-01-00:11:22'), 'EEEE, d MMMM yyyy HH:mm:ss', locale) 
 from locales;
 
-- Using apostrophes in the format string:
-- This is messy since both SQL and Java's DateTimeFormatter require duplicate apostrophes...
select formattimestamp(current timestamp, '''It''''s ''H ''o''''clock'' BBBB', 'en-US') 
  from sysibm.sysdummyu;
  
