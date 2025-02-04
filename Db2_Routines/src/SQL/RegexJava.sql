drop function REGEX_REPLACE(string varchar(32704), regex varchar(32704)) ;
create function REGEX_REPLACE(str varchar(32704), regex varchar(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.de103252.db2.regex.Regex.replace'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
not secured 
deterministic; 

drop function REGEX_MATCHES(str varchar(32704), regex varchar(32704)) ;
create function REGEX_MATCHES(str varchar(32704), regex varchar(32704)) 
returns integer
external name
'ADCDMST.ROUTINES:com.ibm.de103252.db2.regex.Regex.matches'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
not secured 
deterministic; 

drop function REGEX_REPLACE(str         varchar(32704), 
                            regex       varchar(32704), 
                            replacement varchar(32704));
create function REGEX_REPLACE(str         varchar(32704), 
                              regex       varchar(32704), 
                              replacement varchar(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.de103252.db2.regex.Regex.replace'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
not secured 
deterministic;

select regex_matches('araz', '.*r.{1,3}') from sysibm.sysdummyu;