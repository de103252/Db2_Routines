 drop function base64decode(data clob(64M) ccsid unicode);
 
create function BASE64DECODE(data clob(64M) ccsid unicode) 
  returns blob(64M)
  external name 
    'ADCDMST.ROUTINES:com.ibm.de103252.db2.base64.Base64.decode4'
  language java 
  parameter style java 
  no external action 
  allow parallel 
  wlm environment DBDGENVJ 
  asutime no limit 
  not secured 
  deterministic;

create function BASE64DECODE(data VARCHAR(32704) ccsid unicode) 
  returns VARBINARY(24528)
  external name 
    'ADCDMST.ROUTINES:com.ibm.de103252.db2.base64.Base64.decode4'
  language java 
  parameter style java 
  no external action 
  allow parallel 
  wlm environment DBDGENVJ 
  asutime no limit 
  not secured 
  deterministic;
  
CREATE FUNCTION "ADCDMST"."BASE64ENCODE" (DATA BLOB(64M))
  RETURNS CLOB(64M) CCSID UNICODE
  SPECIFIC "ADCDMST"."BASE64ENCODE"
  EXTERNAL NAME 'com.ibm.de103252.db2.base64.Base64.encode4'
  LANGUAGE JAVA
  PARAMETER STYLE JAVA
  DETERMINISTIC
  FENCED
  READS SQL DATA
  NO EXTERNAL ACTION
  ALLOW PARALLEL
  WLM ENVIRONMENT DBCGENVJ
  ASUTIME NO LIMIT
  NOT SECURED;
  
CREATE FUNCTION "ADCDMST"."BASE64ENCODE" (DATA VARBINARY(24528))
  RETURNS VARCHAR(32704) CCSID UNICODE
  SPECIFIC "ADCDMST"."BASE64ENCODE"
  EXTERNAL NAME 'com.ibm.de103252.db2.base64.Base64.encode4'
  LANGUAGE JAVA
  PARAMETER STYLE JAVA
  DETERMINISTIC
  FENCED
  READS SQL DATA
  NO EXTERNAL ACTION
  ALLOW PARALLEL
  WLM ENVIRONMENT DBCGENVJ
  ASUTIME NO LIMIT
  NOT SECURED;
 
SELECT base64encode(cast('Uli Seelbach' as blob)) from sysibm.sysdummyu;

SELECT base64decode('VWxpIFNlZWxiYWNo') from sysibm.sysdummyu;
