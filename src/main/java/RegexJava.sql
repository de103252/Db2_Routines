-- =============================================================================
-- Regular Expression Functions
-- =============================================================================
-- Author: Uli Seelbach
--
-- Overview:
-- This module provides Java-based regular expression functions for
-- Db2 for z/OS. The functions support pattern matching and replacement
-- operations using Java regular expression syntax.
--
-- Implementation:
-- All functions are implemented as Java external functions using the
-- com.ibm.db2.regex.Regex class in the ADCDMST.ROUTINES JAR file.
--
-- Notes:
-- - Input and output use VARCHAR(32704)
-- - Patterns follow Java regular expression syntax
-- - Matching returns an integer indicator
-- - Replacement is available in two-argument and three-argument forms
-- =============================================================================

set current schema = 'SYSFUN';

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

-- Check for valid domain names
-- https://en.wikipedia.org/wiki/Domain_name#Domain_name_syntax
-- https://en.wikipedia.org/wiki/Internationalized_email_address#Internationalized_domain_names
with
names as (
  select token from table(split('de.ibm.com,foo-bar,not\,a\,domain\,name'))
)
select token, regex_matches(token, '^([a-z][a-z0-9-]+(\.|-*\.))+[a-z]{2,6}$') matches
  from names;

-- Performance check: Perform a match 1M times
select sum(regex_matches('de.ibm.com', '^([a-z][a-z0-9-]+(\.|-*\.))+[a-z]{2,6}$')) matches
  from table(generate_series(1, 1000000));

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

-- Made with Bob
