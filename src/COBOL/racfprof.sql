-- =====================================================================
-- RACF PROFILE LOOKUP FUNCTION
-- =====================================================================
-- Retrieve the RACF profile name protecting a dataset.
--
-- Features:
-- - Query RACF security information for datasets
-- - Support for volume-specific lookups
-- - COBOL-based external function
-- - EBCDIC parameter handling
-- - Executes under user's security context
--
-- Function:
-- - racfprofile(dsname, volume): Returns RACF profile name for dataset
--
-- Parameters:
-- - dsname: Dataset name (up to 44 characters)
-- - volume: Volume serial (6 characters, nullable)
--
-- Returns:
-- - VARCHAR(44): RACF profile name protecting the dataset
--
-- Usage Examples:
-- - Lookup profile: SELECT racfprofile('ADCDMST.JOB.CNTL', NULL) FROM SYSIBM.SYSDUMMYU
-- - With volume: SELECT racfprofile('MY.DATASET', 'VOL001') FROM SYSIBM.SYSDUMMYU
-- =====================================================================

create function racfprofile(dsname varchar(44), volume char(6))
  returns varchar(44)
  language cobol
  parameter style sql
  parameter ccsid ebcdic
  security user
  external name racfprof;

select racfprofile('ADCDMST.LOAD', cast(NULL as char(6))) as racf_profile
  from sysibm.sysdummyu;

call sysproc.admin_ds_list('ADCDMST.*', 'N', 'N', 42, 'N', null, null);
select * from sysibm.dslist;
