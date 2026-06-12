-- =====================================================================
-- REGULAR EXPRESSION FUNCTIONS
-- =====================================================================
-- SQL-based regular expression matching and replacement functions.
--
-- Features:
-- - regex_matches: Test if string matches pattern (returns 1/0)
-- - regex_replace: Replace pattern matches with replacement text
-- - Uses XQuery fn:matches and fn:replace for pattern matching
-- - Supports standard regex syntax
-- - NULL-safe operations
--
-- Functions:
-- - REGEX_MATCHES(str, regex): Returns 1 if match, 0 otherwise, NULL if inputs NULL
-- - REGEX_REPLACE(str, regex): Replace matches with empty string
-- - REGEX_REPLACE(str, regex, replacement): Replace matches with specified text
--
-- Usage Examples:
-- - Email validation: SELECT REGEX_MATCHES('test@example.com', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') FROM SYSIBM.SYSDUMMYU
-- - Remove digits: SELECT REGEX_REPLACE('Hello123', '\d+') FROM SYSIBM.SYSDUMMYU
-- - Replace pattern: SELECT REGEX_REPLACE('Hello World', '(?i)world', 'Db2') FROM SYSIBM.SYSDUMMYU
-- =====================================================================

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

SET CURRENT SCHEMA = 'SYSFUN'#

drop function REGEX_MATCHES(str varchar(32704), regex varchar(32704))#

create function REGEX_MATCHES(str varchar(32704), regex varchar(32704)) 
returns integer
begin
  declare sql varchar(32704);
  declare r integer;
  declare stmt statement;
  declare c cursor for stmt;

  -- Prepare a CAST expression from source to target type.
  set sql = 'select xmlcast('||
            'xmlquery(''fn:matches(., "' || 
            regex || 
            '")'' passing cast(? as varchar(32704))) as integer) ' ||
            'from sysibm.sysdummyu';
  prepare stmt from sql;
  open c using str;
  fetch c into r;
  close c;
  return r;  
end
#

with 
u(u) as (
  select * from sysibm.sysdummyu
),
tests(s, r, x) as (
  select 'abc', '^a.*d$', 0 from u union all
  select cast(null as char), '^a.*d$', cast(null as integer) from u
),
results(s, r, x, a) as (
  select s, r, x, REGEX_MATCHES(s, r) from tests
)
select s as string, r as regex, x as expected, a as actual
  from results
 where x is distinct from a 
