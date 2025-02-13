-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

/*
Test whether a string matches a regular expression.
Returns 1 if yes, and 0 otherwise.
If str, regex or both are NULL, returns NULL.
*/

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
  select s, r, x, regex_matches(s, r) from tests
)
select s as string, r as regex, x as expected, a as actual
  from results
 where x is distinct from a 
