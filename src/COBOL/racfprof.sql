create function racfprofile(dsname varchar(44), volume char(6))
  returns varchar(44)
  language cobol
  parameter style sql
  parameter ccsid ebcdic
  security user
  external name racfprof;

select racfprofile('ADCDMST.JOB.CNTL', cast(NULL as char(6)))
  from sysibm.sysdummyu;

call sysproc.admin_ds_list('ADCDMST.*', 'N', 'N', 42, 'N', null, null);
select * from sysibm.dslist