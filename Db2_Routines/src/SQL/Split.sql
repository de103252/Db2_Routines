drop function sysfun.split(input varchar(32704));
drop function sysfun.split(input clob);

create function sysfun.split(input varchar(32704))
returns table (seqno integer, token varchar(32704))
return
select seqno, token
  from xmltable('fn:tokenize(., ",")' passing xmltext(input)
             columns seqno for ordinality
                   , token varchar(32704) path '.');

create function sysfun.split(input clob)
returns table (seqno integer, token varchar(32704))
return
select seqno, token
  from xmltable('fn:tokenize(., ",")' passing xmltext(input)
             columns seqno for ordinality
                   , token varchar(32704) path '.');
                   
select * from table(split('asdf,h&m,foobar'))                    