-- =====================================================================
-- TEST SUITE FOR STRING SPLIT TABLE FUNCTION
-- =====================================================================
-- Tests for the split() and tokenize() functions that split strings
-- into tables of tokens.
--
-- Test Coverage:
-- - Token count with custom regex
-- - XMLTable with custom regex
-- - split() function with custom regex
-- - tokenize() function standalone
-- - Basic comma-separated split
-- - Using split results in WHERE clause
-- =====================================================================

--<ScriptOptions statementTerminator=";"/>
--#SET TERMINATOR ;

-----------------------------------------------------------------------
-- Test 1: Token count with custom regex
-----------------------------------------------------------------------

select xmlquery('fn:count(x)' passing xmlelement(name "a", tokenize('one:two;three|four', '[:\|;]'))) from sysibm.sysdummyu;

-----------------------------------------------------------------------
-- Test 2: XMLTable with custom regex
-----------------------------------------------------------------------

select seqno, token
  from xmltable('t' passing xmlelement(name "a", tokenize('one:two;three|four', '[:\|;]'))
             columns seqno for ordinality
                   , token varchar(32704) path '.')
;

-----------------------------------------------------------------------
-- Test 3: split() function with custom regex
-----------------------------------------------------------------------

select seqno, token
  from table(split('one:two;three|four', '[:\|;]'));

-----------------------------------------------------------------------
-- Test 4: tokenize() function standalone
-----------------------------------------------------------------------

select tokenize('one:two;three|four', '[:\|;]')
  from sysibm.sysdummyu;

-----------------------------------------------------------------------
-- Test 5: Basic comma-separated split
-----------------------------------------------------------------------

select *
  from table(split('EMP,DEPT,PARTS,SUPPLIERS'));
  
-----------------------------------------------------------------------
-- Test 6: Using split results in WHERE clause
-----------------------------------------------------------------------

select *
  from sysibm.systables
 where name in (select token from table(split('EMP,DEPT,PARTS,SUPPLIERS')));

-- Made with Bob
