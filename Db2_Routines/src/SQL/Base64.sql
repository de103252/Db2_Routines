 drop function base64decode(data clob(64M) ccsid unicode);
 
create function BASE64DECODE(data clob(64M) ccsid unicode) 
  specific base64decode_clob2blob
  returns blob(64M)
  external name 
    'ADCDMST.ROUTINES:com.ibm.db2.base64.Base64.decode'
  language java 
  parameter style java 
  no external action 
  allow parallel 
  wlm environment DBDGENVJ 
  asutime no limit 
  deterministic;

drop function BASE64DECODE(data VARCHAR(32704) ccsid unicode);
create function BASE64DECODE(data VARCHAR(32704) ccsid unicode) 
  specific base64decode_char2binary
  returns VARBINARY(24528)
  external name 
    'ADCDMST.ROUTINES:com.ibm.db2.base64.Base64.decode'
  language java 
  parameter style java 
  no external action 
  allow parallel 
  wlm environment DBDGENVJ 
  asutime no limit 
  deterministic;
  
drop function base64encode (data blob(64m));
create function base64encode (data blob(64m))
  specific base64encode_blob2clob
  returns clob(64m) ccsid unicode
  external name 'ADCDMST.ROUTINES:com.ibm.db2.base64.Base64.encode'
  language java
  parameter style java
  deterministic
  fenced
  reads sql data
  no external action
  allow parallel
  wlm environment DBDGENVJ
  asutime no limit
  ;
  
drop function base64encode (data varbinary(24528));
create function base64encode (data varbinary(24528))
  specific base64encode_binary2char
  returns varchar(32704) ccsid unicode
  external name 'ADCDMST.ROUTINES:com.ibm.db2.base64.Base64.encode'
  language java
  parameter style java
  deterministic
  fenced
  reads sql data
  no external action
  allow parallel
  wlm environment DBDGENVJ
  ;
 
SELECT base64encode(cast('Uli Seelbach' as blob)) from sysibm.sysdummyu;

SELECT base64decode(clob('VWxpIFNlZWxiYWNo')) from sysibm.sysdummyu;
