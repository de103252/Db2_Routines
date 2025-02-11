drop function REGEX_REPLACE(string varchar(32704), regex varchar(32704)) ;
create function REGEX_REPLACE(str varchar(32704), regex varchar(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.regex.Regex.replace'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic; 

drop function REGEX_MATCHES(str varchar(32704), regex varchar(32704)) ;
create function REGEX_MATCHES(str varchar(32704), regex varchar(32704)) 
returns integer
external name
'ADCDMST.ROUTINES:com.ibm.db2.regex.Regex.matches'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
deterministic; 

drop function REGEX_REPLACE(str         varchar(32704), 
                            regex       varchar(32704), 
                            replacement varchar(32704));
create function REGEX_REPLACE(str         varchar(32704), 
                              regex       varchar(32704), 
                              replacement varchar(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.regex.Regex.replace'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic;

select regex_matches('araz', '.*r.{1,3}') from sysibm.sysdummyu;

-- Turn X into U, case insensitive
select regex_replace('Ho Ho x X xXXx',
                     '(?i)x',
                     'u')
                     from sysibm.sysdummyu; 
                     
select regex_replace('Never say never again',
                     '\b(\w+)(?:\W+\1\b)+',
                     '$1')
                     from sysibm.sysdummyu;  
                                         
-- Remove duplicate words
select regex_replace('This is a very very very simple example',
                     '\b(\w+)(?:\W+\1\b)+',
                     '$1')
                     from sysibm.sysdummyu; 