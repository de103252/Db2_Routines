-- =============================================================================
-- Test Cases for JSON to XML Conversion and Formatting Functions
-- =============================================================================
-- This file contains demonstration and test queries for the JSON functions
-- defined in src/main/java/JsonToXML.sql
--
-- Functions tested:
-- - JSON2XML: Converts JSON to XML format
-- - JSON2XMLC: Converts JSON to XML character string
-- - JSON_PRETTY_PRINT: Formats JSON with indentation
-- =============================================================================

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
  from x, xmltable('customer/orders/items' passing jsonx
                columns customer_id        integer     path '../../id'
                      , customer_is_active integer     path 'xs:boolean(../../isActive)'
                      , orderId            varchar(8)  path '../orderId'
                      , item               varchar(32) path '.');

/******************************************************************************
Demonstration of JSON_PRETTY_PRINT
******************************************************************************/
-- Format compact JSON with 2-space indentation
select json_pretty_print('{"customer":{"id":101,"name":"Alice","isActive":true,"orders":[{"orderId":"A-555","items":["Laptop","Mouse"]},{"orderId":"B-777","items":["Monitor"]}]}}', 4)
  from sysibm.sysdummyu;

-- Made with Bob
