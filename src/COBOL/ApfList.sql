create function apflist()
  returns table(seqid integer, dsname varchar(44), volume varchar(6))
  language cobol
  program type main
  not deterministic
  parameter style sql
  parameter ccsid ebcdic
  scratchpad
  security user
  external name apflist;
  
select *
  from table(apflist());