/*
Routines to convert JSON to XML.
*/
drop function JSON2XML(json varchar(32704));
drop function JSON2XML(json clob);
 
create function JSON2XML(json varchar(32704)) 
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

create function JSON2XML(json clob(32M)) 
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

/******************************************************************************
Demonstration of JSON2XML
******************************************************************************/
select json2xml('{
  "customer": {
    "id": 101,
    "name": "Alice",
    "isActive": true,
  "orders": [
    {
      "orderId": "A-555",
      "items": ["Laptop", "Mouse"]
    },
    {
      "orderId": "B-777",
      "items": ["Monitor"]
    }
  ]
}
}
') from sysibm.sysdummyu;


-- Unfortunately, Db2 for z/OS does not have a JSON_TABLE function. Using JSON2XML, we
-- can convert the JSON data to XML and then use XMLTABLE to extract data in relational format.
with x(jsonx) as ( 
select json2xml('{
  "customer": {
    "id": 101,
    "name": "Alice",
    "isActive": true,
  "orders": [
    {
      "orderId": "A-555",
      "items": ["Laptop", "Mouse"]
    },
    {
      "orderId": "B-777",
      "items": ["Monitor"]
    }
  ]
}
}
') from sysibm.sysdummyu
)
select customer_id, customer_is_active, orderId, item
  from x, xmltable('customer/orders/items' passing xmlparse(jsonx)
                columns customer_id        integer     path '../../id'
                      , customer_is_active integer     path 'xs:boolean(../../isActive)'
                      , orderId            varchar(8)  path '../orderId'
                      , item               varchar(32) path '.')
