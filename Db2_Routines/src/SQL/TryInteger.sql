--<ScriptOptions statementTerminator="#"/>

drop function sysfun.try_integer(str varchar(32704))#
drop function sysfun.try_smallint(str varchar(32704))#
drop function sysfun.try_bigint(str varchar(32704))#

create function sysfun.try_integer(str varchar(32704))
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

create function sysfun.try_smallint(str varchar(32704))
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

create function sysfun.try_bigint(str varchar(32704))
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

with values(v) as (
  select '' from sysibm.sysdummyu union all
  select '  42   ' from sysibm.sysdummyu union all
  select 'aa42bb' from sysibm.sysdummyu union all
  select '  42a' from sysibm.sysdummyu union all
  select '  42a' from sysibm.sysdummyu union all
  select '  42a' from sysibm.sysdummyu union all
  select '  -9223372036854775808' from sysibm.sysdummyu union all
  select '  9223372036854775807' from sysibm.sysdummyu union all
  select '  9223372036854775808 ' from sysibm.sysdummyu union all
  select '  -9223372036854775809' from sysibm.sysdummyu
)
select v, 
       try_integer(v)   as try_integer, 
       try_smallint(v)  as try_smallint,
       try_bigint(v)    as try_bigint
  from values
#

