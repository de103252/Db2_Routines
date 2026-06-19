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

-- Made with Bob
