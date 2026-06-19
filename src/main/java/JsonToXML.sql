-- =============================================================================
-- JSON to XML Conversion and Formatting Functions
-- =============================================================================
-- Author: Uli Seelbach
--
-- Overview:
-- This module provides Java-based functions to convert JSON data to XML format
-- and format JSON for readability in Db2 for z/OS. These functions enable the
-- use of XMLTABLE to query JSON data since unfortunately, there is no
-- JSON_TABLE function for Db2 z/OS.
--
-- Implementation:
-- All functions are implemented as Java external functions using the
-- com.ibm.db2.json.Json class in the ADCDMST.ROUTINES JAR file.
--
-- Functions:
-- - JSON2XMLC: Returns VARCHAR(32704) or CLOB(32M) string representation
-- - JSON2XML: Returns native XML type (wraps JSON2XMLC with XMLPARSE)
-- - JSON_PRETTY_PRINT: Formats JSON with configurable indentation
--
-- Notes:
-- - Supports both VARCHAR(32704) and CLOB(32M) input sizes
-- - JSON2XMLC returns character string for intermediate processing
-- - JSON2XML returns parsed XML type ready for XMLTABLE queries
-- - JSON_PRETTY_PRINT accepts indent parameter (typically 2 or 4 spaces)
-- - Enables JSON querying via XMLTABLE after conversion
-- - Functions are deterministic and allow parallel execution
-- =============================================================================
drop function JSON2XML(json varchar(32704));
drop function JSON2XML(json clob);

drop function JSON2XMLC(json varchar(32704));
drop function JSON2XMLC(json clob);

create function JSON2XMLC(json varchar(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.json.Json.jsonStringToXML'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic;

create function JSON2XMLC(json clob(32M)) 
returns clob(32M)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.json.Json.jsonClobToXML'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic;

create function JSON2XML(json varchar(32704))
  returns XML
  deterministic
  no external action
  return xmlparse(json2xmlc(json))
;

create function JSON2XML(json clob)
  returns XML
  deterministic
  no external action
  return xmlparse(json2xmlc(json))
;


drop function JSON_PRETTY_PRINT(json clob(32M), indent integer);
drop function JSON_PRETTY_PRINT(json varchar(32704), indent integer);

create function JSON_PRETTY_PRINT(json clob(32M), indent integer) 
returns clob(32M)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.json.Json.prettyPrintJsonClob'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic;

create function JSON_PRETTY_PRINT(json varchar(32704), indent integer)
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.json.Json.prettyPrintJson'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic;

-- Made with Bob
