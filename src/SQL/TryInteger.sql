/*
The TRY_xxx functions try to convert the string value passed
to an integer type. The conversion is tried in the same way
as the respective built-in function and follows the same rules.
Leading and trailing blanks are therefore permitted.
If the string cannot be converted to the
target type, NULL is returned and an SQL warning
(SQLSTATE 02018) is raised.
*/

drop function sysfun.try_integer(str varchar(255));
drop function sysfun.try_smallint(str varchar(255));
drop function sysfun.try_bigint(str varchar(255));

-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #


create function sysfun.try_integer(str varchar(255))
  returns integer
  returns null on null input
  parameter ccsid unicode
  deterministic
  no external action
begin
  declare exit handler for sqlstate '22018' 
  begin 
    signal sqlstate '02018'
       set message_text = '‪THE‬‎ ‪VALUE‬‎ ‪OF‬‎ ‪A‬‎ ‪STRING‬‎ ‪ARGUMENT‬‎ ‪WAS‬‎ ‪NOT‬‎ ' ||
                          '‪ACCEPTABLE‬‎ ‪TO‬‎ ‪THE‬‎ ‪SYSIBM‬‎.‪INTEGER‬‎ ‪FUNCTION‬‎.‪‬‎';
    return null;
  end;
  return int(str);
end
#

create function sysfun.try_smallint(str varchar(255))
  returns smallint
  returns null on null input
  parameter ccsid unicode
  deterministic
  no external action
begin
  declare exit handler for sqlstate '22018' 
  begin 
    signal sqlstate '02018'
       set message_text = '‪THE‬‎ ‪VALUE‬‎ ‪OF‬‎ ‪A‬‎ ‪STRING‬‎ ‪ARGUMENT‬‎ ‪WAS‬‎ ‪NOT‬‎ ' ||
                          '‪ACCEPTABLE‬‎ ‪TO‬‎ ‪THE‬‎ ‪SYSIBM‬‎.‪SMALLINT‬‎ ‪FUNCTION‬‎.‪‬‎';
    return null;
  end;
  return smallint(str);
end
#

create function sysfun.try_bigint(str varchar(255))
  returns bigint
  returns null on null input
  parameter ccsid unicode
  deterministic
  no external action
begin
  declare exit handler for sqlstate '22018' 
  begin 
    signal sqlstate '02018'
       set message_text = '‪THE‬‎ ‪VALUE‬‎ ‪OF‬‎ ‪A‬‎ ‪STRING‬‎ ‪ARGUMENT‬‎ ‪WAS‬‎ ‪NOT‬‎ ' ||
                          '‪ACCEPTABLE‬‎ ‪TO‬‎ ‪THE‬‎ ‪SYSIBM‬‎.BIGINT ‪FUNCTION‬‎.‪‬‎';
    return null;
  end;
  return bigint(str);
end
#

-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;


-----------------------------------------------------------------------
-- Test
-----------------------------------------------------------------------

select try_integer('42')        answer1,
        try_integer('  42  ')   answer2,
        try_integer('fortytwo') answer3
  from sysibm.sysdummy1;
  
with
u(null_s, null_i, null_b) as (
  select cast(null as smallint)
       , cast(null as integer)
       , cast(null as bigint)
    from sysibm.sysdummyu
),
values(v, es, ei, eb) as (
            select '',                       null_s, null_i, null_b               from u
  union all select '  42   ',                42,     42,     42                   from u
  union all select '  42.42 ',               42,     42,     42                   from u
  union all select 'aa42bb',                 null_s, null_i, null_b               from u
  union all select '  42a',                  null_s, null_i, null_b               from u
  union all select '  42a',                  null_s, null_i, null_b               from u
  union all select '  42a',                  null_s, null_i, null_b               from u
  union all select '  -9223372036854775808', null_s, null_i, -9223372036854775808 from u
  union all select '  9223372036854775807',  null_s, null_i, 9223372036854775807  from u
  union all select '  9223372036854775808 ', null_s, null_i, null_b               from u
  union all select '  -9223372036854775809', null_s, null_i, null_b               from u
),
results as (
select v.*, try_smallint(v) as, try_integer(v) ai, try_bigint(v) ab
  from values v
)
select *
  from results
 where as is distinct from es
    or ai is distinct from ei
    or ab is distinct from eb
    or 1 = 1 -- Remove to see wrong results only
;
