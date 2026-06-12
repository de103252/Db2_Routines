-- =====================================================================
-- STRING SPLIT TABLE FUNCTION
-- =====================================================================
-- Split comma-separated string into table of tokens.
--
-- Features:
-- - Returns table with sequence number and token columns
-- - Supports VARCHAR and CLOB input types
-- - Uses XQuery fn:tokenize for parsing
-- - Escaped commas (\,) are preserved in tokens
-- - Returns tokens in original order with sequence numbers
--
-- Functions:
-- - split(input VARCHAR(32704)): Split VARCHAR with escaped comma support
-- - split(input CLOB): Split CLOB without escape support
--
-- Limitations:
-- - VARCHAR version: Escaped commas (\,) are preserved
-- - CLOB version: No escape mechanism, tokens cannot contain commas
--
-- Usage Examples:
-- - Basic split: SELECT * FROM TABLE(split('apple,banana,cherry'))
-- - With escapes: SELECT * FROM TABLE(split('item1,item\,with\,commas,item3'))
-- - CLOB split: SELECT * FROM TABLE(split(CAST('a,b,c' AS CLOB)))
-- =====================================================================

SET CURRENT SCHEMA = 'SYSFUN'#

drop function split(input varchar(32704))#

create function split(input varchar(32704))
returns table (seqno integer, token varchar(32704))
return
select seqno, replace(token, ux'241e', ',')
  from xmltable('fn:tokenize(., ",")' 
                passing xmltext(replace(input, '\,', ux'241e'))
             columns seqno for ordinality
                   , token varchar(32704) path '.');

drop function split(input clob)#
create function split(input clob)
returns table (seqno integer, token varchar(32704))
return
select seqno, token
  from xmltable('fn:tokenize(., ",")' passing xmltext(input)
             columns seqno for ordinality
                   , token varchar(32704) path '.');
                   
select * from table(split('asdf,h&m,foobar,<,>'));

--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

drop function split(input varchar(32704), regex varchar(1024))#

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


-- drop function split(input varchar(32704), regex varchar(1024));

create function split(input varchar(32704), regex varchar(1024))
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
