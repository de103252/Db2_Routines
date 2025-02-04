 drop function FORMATTIMESTAMP(ts timestamp, format varchar(32704)) ; 
 create function FORMATTIMESTAMP(ts timestamp, format varchar(32704)) 
 returns varchar(32704)
 external name 'ADCDMST.ROUTINES:com.ibm.de103252.db2.date.Date.format2'
 language java 
 parameter style java 
 no external action 
 allow parallel 
 wlm environment DBCGENVJ 
 asutime no limit 
 not secured 
 deterministic;
 
 drop function FORMATTIMESTAMP(ts timestamp, format varchar(32704), locale varchar(128))  ; 
 create function FORMATTIMESTAMP(ts timestamp, format varchar(32704), locale varchar(128)) 
 returns varchar(32704)
 external name 'ADCDMST.ROUTINES:com.ibm.de103252.db2.date.Date.format3'
 language java 
 parameter style java 
 no external action 
 allow parallel 
 wlm environment DBCGENVJ 
 asutime no limit 
 not secured 
 deterministic;
 
 select formattimestamp(current timestamp, 'EEEE, d MMM yyyy HH:mm:ss Z', 'de-DE') 
 from sysibm.sysdummyu;
 select varchar_format(current timestamp, 'asdf') from sysibm.sysdummyu;

 select formattimestamp(current timestamp, 'hh ''o''''clock'' a, zzzz', 'en-US') 
 from sysibm.sysdummyu;
 
