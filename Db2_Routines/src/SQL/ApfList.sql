create function apflist()
  returns table(dsname varchar(44), volume varchar(6))
  language cobol
  parameter style sql
  parameter ccsid ebcdic
  scratchpad
  security user
  external name apflist;
  
select *
  from table(apflist());