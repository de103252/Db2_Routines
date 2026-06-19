-- =============================================================================
-- Test Cases for Regular Expression Functions
-- =============================================================================
-- This file contains demonstration and test queries for the regex functions
-- defined in RegexJava.sql
--
-- Functions tested:
-- - REGEX_MATCHES: Matches a regular expression against a string
-- - REGEX_REPLACE: Replaces regular expression matches within a string
-- =============================================================================

-- Check for valid domain names
-- https://en.wikipedia.org/wiki/Domain_name#Domain_name_syntax
-- https://en.wikipedia.org/wiki/Internationalized_email_address#Internationalized_domain_names
with
names as (
  select token from table(split('de.ibm.com,foo-bar,not\,a\,domain\,name'))
)
select token, regex_matches(token, 
'^([a-z][a-z0-9-]+(\.|-*\.))+[a-z]{2,6}$') matches
  from names;

-- Performance check: Perform a match 1M times
select sum(regex_matches('de.ibm.com', 
                         '^([a-z][a-z0-9-]+(\.|-*\.))+[a-z]{2,6}$')) matches
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
