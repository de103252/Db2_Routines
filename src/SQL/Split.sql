/*
The SPLIT function splits an input string 
into tokens separated by commas.
Unfortunately, as there is no way to "escape" commas,
the input tokens cannot contain any.
*/

drop function sysfun.split(input varchar(32704));

create function sysfun.split(input varchar(32704))
returns table (seqno integer, token varchar(32704))
return
select seqno, replace(token, ux'241e', ',')
  from xmltable('fn:tokenize(., ",")' 
                passing xmltext(replace(input, '\,', ux'241e'))
             columns seqno for ordinality
                   , token varchar(32704) path '.');

drop function sysfun.split(input clob);
create function sysfun.split(input clob)
returns table (seqno integer, token varchar(32704))
return
select seqno, token
  from xmltable('fn:tokenize(., ",")' passing xmltext(input)
             columns seqno for ordinality
                   , token varchar(32704) path '.');
                   
select * from table(split('asdf,h&m,foobar,<,>'));

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

drop function sysfun.split(input varchar(32704), regex varchar(1024));

drop function tokenize(str varchar(32704), regex varchar(1024))#
create function tokenize(str varchar(32704), regex varchar(1024))
returns xml
begin
  declare sql varchar(32704);
  declare r xml;
  declare stmt statement;
  declare c cursor for stmt;

  -- Prepare a CAST expression from source to target type.
  set sql = 'select '||
            'xmlquery(''for $i in fn:tokenize(., "' || 
            regex || 
            '") return <t>{$i}</t>'' passing cast(? as varchar(32704)))' ||
            'from sysibm.sysdummyu';
  prepare stmt from sql;
  open c using str;
  fetch c into r;
  close c;
  return r;  
end
#      

-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;


-- drop function sysfun.split(input varchar(32704), regex varchar(1024));

create function sysfun.split(input varchar(32704), regex varchar(1024))
returns table (seqno integer, token varchar(32704))
return
select seqno, token
  from xmltable('t' passing xmlelement(name "a", tokenize(input, regex))
             columns seqno for ordinality
                   , token varchar(32704) path '.')
;

-----------------------------------------------------------------------
-- Test
-----------------------------------------------------------------------

select xmlquery('fn:count(x)' passing xmlelement(name "a", tokenize('one:two;three|four', '[:\|;]'))) from sysibm.sysdummyu;

select seqno, token
  from xmltable('t' passing xmlelement(name "a", tokenize('one:two;three|four', '[:\|;]'))
             columns seqno for ordinality
                   , token varchar(32704) path '.')
;

select seqno, token
  from table(split('one:two;three|four', '[:\|;]'));

select tokenize('one:two;three|four', '[:\|;]')
  from sysibm.sysdummyu;

select *
  from table(split('EMP,DEPT,PARTS,SUPPLIERS'));
  
select *
  from sysibm.systables
 where name in (select token from table(split('EMP,DEPT,PARTS,SUPPLIERS')));
