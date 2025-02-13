--<ScriptOptions statementTerminator="#"/>

create procedure deploy_jar(jar     blob(1M), 
                            jarname varchar(257))
  called on null input                            
begin
  declare rc integer default 0;
  declare wlmenv varchar(96);
  declare jarschema, jar_id varchar(257);
  declare status varchar(120);
  
  if posstr(jarname, '.') = 0 then
    set jarschema = current schema;
    set jar_id = jarname;
  else
    set jarschema = substr(jarname, 1, posstr(jarname, '.') - 1);
    set jar_id = substr(jarname, 1, posstr(jarname, '.') + 1);
  end if;
  
  if jar is null then
    -- Remove the Jar
    call SQLJ.REMOVE_JAR(jarname, 0);
  elseif (select 1 from sysibm.sysjarobjects jo 
           where (jo.jarschema, jo.jar_id) = (jarschema, jar_id)) 
         is not null
  then
    -- Replace the Jar and refresh all Java WLM environments
    call SQLJ.DB2_REPLACE_JAR(jar, jarname);
    for select distinct wlm_environment
          from sysibm.sysroutines 
         where language = 'JAVA'
    do 
      call sysproc.wlm_refresh(wlm_environment, null, status, rc);
    end for;  
  else
    -- Install the Jar
    call SQLJ.DB2_INSTALL_JAR(jar, jarname, 0);
  end if;
  get diagnostics rc = DB2_RETURN_STATUS;
  return rc;
end
#


select deploy_jar(cast(? as blob(1M)), 'ROUTINES')
  from sysibm.sysdummyu
#

select *
  from sysibm.sysjarobjects
#
