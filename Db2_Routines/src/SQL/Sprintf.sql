
drop function SPRINTF(format varchar(32704), packed_data varbinary(32704)); 
create function SPRINTF(format varchar(32704), packed_data varbinary(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.sprintf.Sprintf.sprintf'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
not secured 
deterministic; 

drop function SPRINTF(locale varchar(64), format varchar(32704), packed_data varbinary(32704)); 
create function SPRINTF(locale varchar(64), format varchar(32704), packed_data varbinary(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.sprintf.Sprintf.sprintf'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
not secured 
deterministic; 

with p(p) as (
 select               pack(ccsid 1208, 
                    current timestamp
                    )
                    from sysibm.sysdummyu
)
select p, sprintf('', '%1$tB', p) from p;
  