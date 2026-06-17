call SYSPROC.ADMIN_DS_LIST('DSND10.DBDG.ARCLOG*.**', 'N', 'N', 100000, 'N', ?, ?);
select * from sysibm.dslist;

select * from sysibm.syscopy;

 SELECT COUNT(*), GBPCACHE , 'IXP'  FROM    SYSIBM.SYSINDEXPART
  GROUP BY GBPCACHE WITH UR ;
  SELECT COUNT(*), GBPCACHE , 'TBP'  FROM    SYSIBM.SYSTABLEPART
  GROUP BY GBPCACHE WITH UR ;
  SELECT IX.DBNAME, IX.INDEXSPACE,
  IXP.PARTITION, IXP.GBPCACHE, IXP.SPACE
  FROM    SYSIBM.SYSINDEXPART IXP, SYSIBM.SYSINDEXES IX
  WHERE IX.CREATOR = IXP.IXCREATOR AND IX.NAME = IXP.IXNAME
  AND   IXP.GBPCACHE NOT IN (' ') WITH UR ;
  SELECT DBNAME, TSNAME, PARTITION, GBPCACHE, SPACE
  FROM    SYSIBM.SYSTABLEPART WHERE
  GBPCACHE NOT IN (' ' ) WITH UR ;
  
  SELECT COUNT(*) FROM SYSIBM.SYSTABLESPACE
  WHERE LOG IN ('N' , 'X') WITH UR ;
  SELECT       *  FROM SYSIBM.SYSTABLESPACE
  WHERE LOG IN ('N' , 'X') WITH UR ;
#
drop function get_config()#
  
create function get_config()
returns xml
modifies sql data
begin 
  declare major integer default 2;
  declare minor integer default 0;
  declare out blob(2g);
  declare message blob(64k);
  call sysproc.get_config(major, minor, null, null, null, out, message);
  return xmlparse(out);
end
#

create table config(xml xml) ccsid unicode;

insert into config(xml) values (get_config())#
select get_config() from sysibm.sysdummyu#

select t.ename, count(*) from config
  cross join xmltable('//dict/*' passing xml
                columns ename varchar(64) path 'local-name(.)'
                ) t
                group by t.ename#

create function dict2table(dict xml)
returns table(key     varchar(64),
              string  varchar(64),  
              integer integer    ,  
              date    varchar(64),  
              dict    xml        ,  
              array   xml)
return                        
select k.key, v.string, v.integer, v.date, v.dict, v.array from config,
             xmltable('/plist/dict/key' passing xml
                columns key varchar(64) path '.',
                        seqno for ordinality
                ) k
        join xmltable('/plist/dict/*[local-name(.) != "key"]' passing xml
                columns 
                string  varchar(64)   path '.[local-name() = "string"]',
                integer integer       path '.[local-name() = "integer"]',
                date    varchar(64)   path '.[local-name() = "date"]',
                dict    xml           path '.[local-name() = "dict"]',
                array   xml           path '.[local-name() = "array"]',
                seqno for ordinality
                ) v
          on k.seqno = v.seqno
#

select 1 as level, k.key1, v.dvalue, v.ivalue, v.svalue from config,
             xmltable('/plist/dict/key' passing xml
                columns key1 varchar(64) path '.',
                        seqno for ordinality
                ) k
        join xmltable('/plist/dict/*[local-name(.) != "key"]' passing xml
                columns 
                dvalue    xml path '.[local-name() = "dict"]',
                ivalue    integer path '.[local-name() = "integer"]',           
                svalue    varchar(1024) path '.[local-name() = "string"]',           
                seqno for ordinality
                ) v
          on k.seqno = v.seqno
#


                       
  