/*
Generates a series of integer values in the given interval
from start to stop with the given step. Both start and stop
are inclusive; step must not be 0.
*/

drop   function sysfun.generate_series(start integer, 
                                       stop  integer, 
                                       step  integer);
                                       
create function sysfun.generate_series(start integer, 
                                       stop  integer, 
                                       step  integer)
returns table(value integer)
  deterministic
  no external action
return
with
series(seq, value) as (
  select 1, start from sysibm.sysdummyu
   where case when step > 0 and start <= stop then 1 
              when step < 0 and start >= stop then 1
              when step = 0 then raise_error('70815',
                                             'Step must not be zero')
         end is not null
  union all
  select seq + 1, value + step from series
   where seq < 2147483647 -- prevents infinite recursion warning
     and (   step > 0 and value + step <= stop
          or step < 0 and value + step >= stop)
)
select value from series;

/*
Generates a series of integer values in the given interval
from start to stop with an increment of 1. Both start and stop
are inclusive.
*/
drop   function sysfun.generate_series(start integer, 
                                       stop  integer);
                                       
create function sysfun.generate_series(start integer, 
                                       stop  integer)
returns table(value integer)
  deterministic
  no external action
return
with
series(value) as (
  select start from sysibm.sysdummyu
   where start <= stop
  union all
  select value + 1 from series
   where value < 2147483647
     and value + 1 <= stop
)
select value from series;

select value
  from table(generate_series(1, 5));
  
select value
  from table(generate_series(0, 15, 5));

select value
  from table(generate_series(10, 0, -1));
  
select current date + (6 - dayofweek_iso(current date) + value) days
  from table(generate_series(0, 2*7, 7));
  
