-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
--<ScriptOptions statementTerminator="#"/>
--#SET TERMINATOR #

/*
 * Unload Db2 data in CSV format.
 */
drop function UNLOADCSV(statement varchar(32704), filename varchar(32704)) ;

/*
        DEFAULT,
        EXCEL,
        INFORMIX_UNLOAD,
        INFORMIX_UNLOAD_CSV,
        MONGODB_CSV,
        MONGODB_TSV,
        MYSQL,
        ORACLE,
        POSTGRESQL_CSV,
        POSTGRESQL_TEXT,
        RFC4180,
        TDF

*/

/*
allowMissingColumnNames boolean
commentMarker           char
delimiter               string
escape                  char
headerComments          comma-separated strings
lenientEof              boolean
maxRows                 long
nullString              string
quote                   char
quoteMode               ALL, ALL_NON_NULL, MINIMAL, NON_NUMERIC, NONE
recordSeparator         string
skipHeaderRecord        boolean
trailingData            boolean
trailingDelimiter       boolean
trim                    boolean
*/
drop  function UNLOADCSV(statement   varchar(32704), 
                         filename    varchar(32704), 
                         formatName  varchar(32704), 
                         ccsid       integer, 
                         printHeader char);

create function UNLOADCSV(statement varchar(32704), filename varchar(32704)) 
returns bigint
external name 'ADCDMST.ROUTINES:com.ibm.db2.csv.Unload.unload'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
not deterministic; 
;
                          
create function UNLOADCSV(statement   varchar(32704), 
                          filename    varchar(32704), 
                          formatName  varchar(32704), 
                          ccsid       integer, 
                          printHeader char)
returns bigint
external name 'ADCDMST.ROUTINES:com.ibm.db2.csv.Unload.unload(java.lang.String,java.lang.String,java.lang.String,int,java.lang.String)'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
not deterministic; 

select unloadcsv('select * from dsn81310.emp', '/u/adcdmst/emp.csv')
  from sysibm.sysdummyu;

with predef_formats(format) as (
             select 'Default' from sysibm.sysdummyu 
   union all select 'Excel' from sysibm.sysdummyu 
   union all select 'InformixUnload' from sysibm.sysdummyu 
   union all select 'InformixUnloadCsv' from sysibm.sysdummyu
   union all select 'MongoDBCsv' from sysibm.sysdummyu 
   union all select 'MongoDBTsv' from sysibm.sysdummyu
   union all select 'MySQL' from sysibm.sysdummyu
   union all select 'Oracle' from sysibm.sysdummyu
   union all select 'PostgreSQLCsv' from sysibm.sysdummyu
   union all select 'PostgreSQLText' from sysibm.sysdummyu
   union all select 'RFC4180' from sysibm.sysdummyu
   union all select 'TDF' from sysibm.sysdummyu
)
select unloadcsv('select * from dsn81310.emp', '/u/adcdmst/emp_' || format || '.csv', format, 1208, 1)
  from predef_formats;

with cust_formats(format) as (
             select 'trim=true, quoteMode=NON_NUMERIC, nullString=(nix)' from sysibm.sysdummyu 
)
select unloadcsv('select * from dsn81310.emp', '/u/adcdmst/emp_' || row_number() over() || '.csv', format, 1208, 1)
  from cust_formats;

select unloadcsv('select * from dsn81310.emp', '//emp.csv', 'Excel', 1208, 'Y')
  from sysibm.sysdummyu;
    