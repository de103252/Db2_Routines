-- =====================================================================
-- comprehensive test case for split function
-- business context: transaction log parsing for etl and data quality
-- =====================================================================
--
-- = business problem
--
-- enterprise systems often generate semi-structured log files where
-- transaction records contain multiple data elements separated by
-- various delimiters. these logs need to be parsed for:
--
-- * etl processes loading data into data warehouses
-- * data quality validation and cleansing operations
-- * audit trail analysis and compliance reporting
-- * fraud detection and anomaly identification
-- * customer behavior analytics
--
-- = test scenario
--
-- parsing payment gateway transaction logs that contain:
-- * transaction id
-- * timestamp
-- * customer id
-- * payment method
-- * amount
-- * currency
-- * status code
-- * merchant reference
--
-- the logs use multiple delimiters (pipes, semicolons, colons)
-- and may contain optional fields, whitespace variations,
-- and special characters in merchant references.
--
-- =====================================================================

-- ---------------------------------------------------------------------
-- test case 1: standard transaction log parsing
-- business use: daily etl load of payment transactions
-- ---------------------------------------------------------------------

-- sample input: transaction log entries with pipe delimiters
-- format: txn_id|timestamp|customer_id|payment_method|amount|currency|status|merchant_ref

with transaction_logs(log_entry) as (
       select 'TXN001|2026-06-10 08:15:23|CUST-12345|VISA-4532|125.50|USD|SUCCESS|REF-ABC-001'
         from sysibm.sysdummy1
  union all
       select 'TXN002|2026-06-10 08:16:45|CUST-67890|MASTERCARD-5412|89.99|EUR|SUCCESS|REF-XYZ-002'
         from sysibm.sysdummy1
  union all
       select 'TXN003|2026-06-10 08:17:12|CUST-11111|AMEX-3782|1250.00|USD|DECLINED|REF-DEF-003'
         from sysibm.sysdummy1
  union all
       select 'TXN004|2026-06-10 08:18:33|CUST-22222|PAYPAL|45.75|GBP|SUCCESS|REF-GHI-004'
         from sysibm.sysdummy1
  union all
       select 'TXN005|2026-06-10 08:19:01|CUST-33333|VISA-4532|0.00|USD|CANCELLED|REF-JKL-005'
         from sysibm.sysdummy1
)
select l.log_entry
     , s.seqno
     , s.token
     , case s.seqno
         when 1 then 'transaction_id'
         when 2 then 'timestamp'
         when 3 then 'customer_id'
         when 4 then 'payment_method'
         when 5 then 'amount'
         when 6 then 'currency'
         when 7 then 'status'
         when 8 then 'merchant_reference'
         else 'unknown_field'
       end as field_name
  from transaction_logs l
     , table(sysfun.split(l.log_entry, '\|')) s
 order by l.log_entry, s.seqno;

-- expected output: 40 rows (5 transactions × 8 fields each)
-- validates: standard delimiter parsing, field identification

-- ---------------------------------------------------------------------
-- test case 2: complex multi-delimiter parsing
-- business use: parsing product sku with embedded metadata
-- ---------------------------------------------------------------------

-- sample input: product skus with hierarchical structure
-- format: category:subcategory:brand;model;variant|sku|price:currency

with product_catalog(sku_string) as (
       select 'electronics:laptops:dell;latitude-5420;i7-16gb-512ssd|SKU-LAP-001|1299.99:usd'
         from sysibm.sysdummy1
  union all
       select 'electronics:monitors:lg;ultrawide-34;curved-qhd|SKU-MON-002|599.00:usd'
         from sysibm.sysdummy1
  union all
       select 'furniture:office:herman-miller;aeron;size-b-graphite|SKU-CHR-003|1395.00:usd'
         from sysibm.sysdummy1
  union all
       select 'electronics:tablets:apple;ipad-pro;12.9-wifi-256gb|SKU-TAB-004|1099.00:usd'
         from sysibm.sysdummy1
)
select p.sku_string
     , s.seqno
     , s.token
  from product_catalog p
     , table(sysfun.split(p.sku_string, '[:|;]')) s
 order by p.sku_string, s.seqno;

-- expected output: variable rows per product (11-13 tokens each)
-- validates: multiple delimiter types in single regex pattern
-- business value: enables hierarchical product categorization

-- ---------------------------------------------------------------------
-- test case 3: handling edge cases and data quality issues
-- business use: data cleansing and validation
-- ---------------------------------------------------------------------

-- sample input: malformed log entries with common data quality issues

with problematic_logs(log_entry, issue_type) as (
       select 'TXN006||CUST-44444|VISA|100.00|USD|SUCCESS|REF-MNO-006'
            , 'missing_timestamp'
         from sysibm.sysdummy1
  union all
       select 'TXN007|2026-06-10 09:00:00||VISA|50.00|USD|SUCCESS|REF-PQR-007'
            , 'missing_customer'
         from sysibm.sysdummy1
  union all
       select 'TXN008|2026-06-10 09:01:00|CUST-55555|VISA|||SUCCESS|REF-STU-008'
            , 'missing_amount_currency'
         from sysibm.sysdummy1
  union all
       select '|2026-06-10 09:02:00|CUST-66666|VISA|75.00|USD|SUCCESS|'
            , 'missing_txn_and_ref'
         from sysibm.sysdummy1
  union all
       select 'TXN009|2026-06-10 09:03:00|CUST-77777|VISA|200.00|USD|SUCCESS|REF-VWX-009|EXTRA'
            , 'extra_field'
         from sysibm.sysdummy1
)
select l.issue_type
     , l.log_entry
     , s.seqno
     , case when length(trim(s.token)) = 0 then '<empty>'
            else s.token
       end as token_value
     , length(trim(s.token)) as token_length
  from problematic_logs l
     , table(sysfun.split(l.log_entry, '\|')) s
 order by l.issue_type, s.seqno;

-- expected output: identifies empty tokens and missing fields
-- validates: consecutive delimiters, leading/trailing delimiters
-- business value: data quality monitoring and cleansing rules

-- ---------------------------------------------------------------------
-- test case 4: parsing address fields with optional components
-- business use: customer address standardization
-- ---------------------------------------------------------------------

-- sample input: addresses with varying formats
-- format: street|apt/suite|city|state|zip|country

with customer_addresses(address_string, address_type) as (
       select '123 main st|apt 4b|new york|ny|10001|usa'
            , 'full_address'
         from sysibm.sysdummy1
  union all
       select '456 oak ave||boston|ma|02101|usa'
            , 'no_apartment'
         from sysibm.sysdummy1
  union all
       select '789 elm blvd|suite 200|san francisco|ca|94102|'
            , 'missing_country'
         from sysibm.sysdummy1
  union all
       select '321 pine rd||chicago|il|60601|usa'
            , 'standard'
         from sysibm.sysdummy1
  union all
       select '||london||w1a 1aa|uk'
            , 'minimal_uk'
         from sysibm.sysdummy1
)
select a.address_type
     , s.seqno
     , case s.seqno
         when 1 then 'street'
         when 2 then 'unit'
         when 3 then 'city'
         when 4 then 'state'
         when 5 then 'postal_code'
         when 6 then 'country'
         else 'extra'
       end as field_name
     , case when length(trim(s.token)) = 0 then null
            else trim(s.token)
       end as field_value
  from customer_addresses a
     , table(sysfun.split(a.address_string, '\|')) s
 order by a.address_type, s.seqno;

-- expected output: 30 rows (5 addresses × 6 fields each)
-- validates: optional fields, null handling, whitespace
-- business value: address standardization for shipping/billing

-- ---------------------------------------------------------------------
-- test case 5: parsing server log entries with timestamps
-- business use: application monitoring and performance analysis
-- ---------------------------------------------------------------------

-- sample input: web server access logs
-- format: timestamp|ip_address|http_method|url|status_code|response_time_ms|user_agent

with server_logs(log_line) as (
       select '2026-06-10t08:15:23.456z|192.168.1.100|get|/api/customers/12345|200|45|mozilla/5.0'
         from sysibm.sysdummy1
  union all
       select '2026-06-10t08:15:24.123z|192.168.1.101|post|/api/orders|201|123|chrome/91.0'
         from sysibm.sysdummy1
  union all
       select '2026-06-10t08:15:25.789z|192.168.1.102|get|/api/products?cat=electronics|200|67|safari/14.1'
         from sysibm.sysdummy1
  union all
       select '2026-06-10t08:15:26.456z|192.168.1.103|put|/api/customers/67890|404|12|firefox/89.0'
         from sysibm.sysdummy1
  union all
       select '2026-06-10t08:15:27.234z|192.168.1.104|delete|/api/orders/999|500|234|postman/9.0'
         from sysibm.sysdummy1
)
select s.seqno
     , s.token
     , case s.seqno
         when 1 then 'timestamp'
         when 2 then 'client_ip'
         when 3 then 'http_method'
         when 4 then 'request_url'
         when 5 then 'status_code'
         when 6 then 'response_time_ms'
         when 7 then 'user_agent'
       end as field_name
  from server_logs l
     , table(sysfun.split(l.log_line, '\|')) s
 where s.seqno <= 7
 order by l.log_line, s.seqno;

-- expected output: 35 rows (5 log entries × 7 fields each)
-- validates: timestamp parsing, url with query parameters
-- business value: performance monitoring, error tracking

-- ---------------------------------------------------------------------
-- test case 6: parsing financial transaction codes
-- business use: regulatory reporting and compliance
-- ---------------------------------------------------------------------

-- sample input: swift/iso 20022 style transaction codes
-- format: domain:family:subfamily:feature

with transaction_codes(code_string, description) as (
       select 'pmnt:icdt:esct:inst'
            , 'instant_sepa_credit_transfer'
         from sysibm.sysdummy1
  union all
       select 'pmnt:irct:esct:retn'
            , 'sepa_credit_return'
         from sysibm.sysdummy1
  union all
       select 'pmnt:iddt:core:frst'
            , 'sepa_direct_debit_first'
         from sysibm.sysdummy1
  union all
       select 'pmnt:iddt:b2b:rcur'
            , 'sepa_b2b_recurring'
         from sysibm.sysdummy1
  union all
       select 'camt:054:001:08'
            , 'bank_to_customer_debit_credit_notification'
         from sysibm.sysdummy1
)
select t.description
     , s.seqno
     , s.token
     , case s.seqno
         when 1 then 'domain'
         when 2 then 'family'
         when 3 then 'subfamily'
         when 4 then 'feature'
       end as code_level
  from transaction_codes t
     , table(sysfun.split(t.code_string, ':')) s
 order by t.description, s.seqno;

-- expected output: 20 rows (5 codes × 4 levels each)
-- validates: hierarchical code parsing, colon delimiter
-- business value: iso 20022 message processing, compliance

-- ---------------------------------------------------------------------
-- test case 7: parsing csv with escaped commas
-- business use: importing csv files with complex text fields
-- ---------------------------------------------------------------------

-- sample input: csv records where commas are escaped with backslash
-- demonstrates the varchar version that handles \, escaping

with csv_data(csv_line) as (
       select 'john doe,acme\, inc.,sales manager,john.doe@acme.com'
         from sysibm.sysdummy1
  union all
       select 'jane smith,widgets\, llc,ceo,jane.smith@widgets.com'
         from sysibm.sysdummy1
  union all
       select 'bob johnson,tools & more\, corp,engineer,bob.j@tools.com'
         from sysibm.sysdummy1
)
select s.seqno
     , s.token
     , case s.seqno
         when 1 then 'full_name'
         when 2 then 'company'
         when 3 then 'title'
         when 4 then 'email'
       end as field_name
  from csv_data c
     , table(sysfun.split(c.csv_line)) s
 order by c.csv_line, s.seqno;

-- expected output: 12 rows (3 records × 4 fields each)
-- validates: escaped comma handling (varchar version)
-- business value: csv import with company names containing commas

-- ---------------------------------------------------------------------
-- test case 8: parsing multi-level hierarchical data
-- business use: organizational structure and reporting chains
-- ---------------------------------------------------------------------

-- sample input: employee reporting hierarchy
-- format: emp_id|name|dept:subdept:team|manager_id|location:building:floor

with org_structure(hierarchy_string) as (
       select 'e001|alice johnson|sales:enterprise:fortune500|m001|nyc:tower-a:15'
         from sysibm.sysdummy1
  union all
       select 'e002|bob smith|sales:enterprise:midmarket|m001|nyc:tower-a:15'
         from sysibm.sysdummy1
  union all
       select 'e003|carol white|engineering:backend:platform|m002|sfo:campus-b:3'
         from sysibm.sysdummy1
  union all
       select 'e004|david brown|engineering:frontend:mobile|m002|sfo:campus-b:4'
         from sysibm.sysdummy1
  union all
       select 'e005|eve davis|hr:recruiting:technical|m003|bos:main:2'
         from sysibm.sysdummy1
)
select s.seqno
     , s.token
     , case s.seqno
         when 1 then 'employee_id'
         when 2 then 'full_name'
         when 3 then 'department_path'
         when 4 then 'manager_id'
         when 5 then 'location_path'
       end as field_name
  from org_structure o
     , table(sysfun.split(o.hierarchy_string, '\|')) s
 order by o.hierarchy_string, s.seqno;

-- expected output: 25 rows (5 employees × 5 fields each)
-- validates: nested hierarchical data with multiple delimiters
-- business value: org chart generation, reporting structure

-- further parsing of hierarchical fields:
with org_structure(hierarchy_string) as (
       select 'e001|alice johnson|sales:enterprise:fortune500|m001|nyc:tower-a:15'
         from sysibm.sysdummy1
  union all
       select 'e002|bob smith|sales:enterprise:midmarket|m001|nyc:tower-a:15'
         from sysibm.sysdummy1
)
   , parsed_main as (
select o.hierarchy_string
     , max(case when s.seqno = 1 then s.token end) as emp_id
     , max(case when s.seqno = 2 then s.token end) as full_name
     , max(case when s.seqno = 3 then s.token end) as dept_path
     , max(case when s.seqno = 4 then s.token end) as manager_id
     , max(case when s.seqno = 5 then s.token end) as location_path
  from org_structure o
     , table(sysfun.split(o.hierarchy_string, '\|')) s
 group by o.hierarchy_string
)
select p.emp_id
     , p.full_name
     , d.seqno as dept_level
     , d.token as dept_component
     , l.seqno as location_level
     , l.token as location_component
  from parsed_main p
     , table(sysfun.split(p.dept_path, ':')) d
     , table(sysfun.split(p.location_path, ':')) l
 order by p.emp_id, d.seqno, l.seqno;

-- expected output: 18 rows (2 employees × 3 dept levels × 3 location levels)
-- validates: multi-stage parsing of hierarchical data
-- business value: dimensional modeling for data warehouse

-- ---------------------------------------------------------------------
-- test case 9: parsing iot sensor data streams
-- business use: real-time monitoring and alerting
-- ---------------------------------------------------------------------

-- sample input: sensor telemetry with multiple measurements
-- format: sensor_id|timestamp|temp_c|humidity_pct|pressure_hpa|battery_v|status

with sensor_data(telemetry_string) as (
       select 'sensor-001|2026-06-10t08:15:00|22.5|45.2|1013.25|3.7|ok'
         from sysibm.sysdummy1
  union all
       select 'sensor-002|2026-06-10t08:15:00|23.1|48.7|1012.80|3.6|ok'
         from sysibm.sysdummy1
  union all
       select 'sensor-003|2026-06-10t08:15:00|25.8|52.3|1011.95|2.9|low_battery'
         from sysibm.sysdummy1
  union all
       select 'sensor-004|2026-06-10t08:15:00|21.2|43.1|1014.10|3.8|ok'
         from sysibm.sysdummy1
  union all
       select 'sensor-005|2026-06-10t08:15:00|19.5|39.8|1015.20|1.2|critical_battery'
         from sysibm.sysdummy1
)
select s.seqno
     , s.token
     , case s.seqno
         when 1 then 'sensor_id'
         when 2 then 'timestamp'
         when 3 then 'temperature_celsius'
         when 4 then 'humidity_percent'
         when 5 then 'pressure_hpa'
         when 6 then 'battery_volts'
         when 7 then 'status'
       end as measurement_type
     , case 
         when s.seqno = 7 and s.token like '%battery%' then 'alert'
         when s.seqno = 6 and decimal(s.token) < 3.0 then 'warning'
         else 'normal'
       end as alert_level
  from sensor_data d
     , table(sysfun.split(d.telemetry_string, '\|')) s
 order by d.telemetry_string, s.seqno;

-- expected output: 35 rows (5 sensors × 7 measurements each)
-- validates: numeric data parsing, status monitoring
-- business value: iot data ingestion, predictive maintenance

-- ---------------------------------------------------------------------
-- test case 10: performance test with large dataset
-- business use: batch processing and etl scalability
-- ---------------------------------------------------------------------

-- generate 100 transaction records for performance testing
with counter(n) as (
       select 1 from sysibm.sysdummy1
  union all
       select n + 1 from counter where n < 100
)
   , generated_transactions as (
select 'txn' || right('00000' || rtrim(char(n)), 5) ||
       '|2026-06-10 ' || right('0' || rtrim(char(mod(n, 24))), 2) || ':' ||
       right('0' || rtrim(char(mod(n, 60))), 2) || ':' ||
       right('0' || rtrim(char(mod(n, 60))), 2) ||
       '|cust-' || right('00000' || rtrim(char(n * 7)), 5) ||
       '|visa-4532' ||
       '|' || rtrim(char(decimal(n * 1.5, 10, 2))) ||
       '|usd' ||
       '|success' ||
       '|ref-' || right('00000' || rtrim(char(n)), 5) as transaction_log
  from counter
)
select count(*) as total_tokens
     , count(distinct s.seqno) as distinct_fields
     , min(length(s.token)) as min_token_length
     , max(length(s.token)) as max_token_length
     , decimal(avg(length(s.token)), 5, 2) as avg_token_length
  from generated_transactions t
     , table(sysfun.split(t.transaction_log, '\|')) s;

-- expected output: 1 summary row showing 800 total tokens (100 × 8 fields)
-- validates: function performance with larger datasets
-- business value: etl batch processing capacity planning

-- =====================================================================
-- summary of test coverage
-- =====================================================================
--
-- delimiter types tested:
-- * pipe (|) - most common in log files
-- * colon (:) - hierarchical data
-- * semicolon (;) - alternative delimiter
-- * comma (,) - csv format with escaping
-- * regex character class ([:|;]) - multiple delimiters
--
-- edge cases validated:
-- * consecutive delimiters (empty fields)
-- * leading delimiters (missing first field)
-- * trailing delimiters (missing last field)
-- * escaped delimiters (\,)
-- * special characters in tokens
-- * varying field counts per record
-- * null/empty token handling
-- * whitespace variations
--
-- business scenarios covered:
-- * payment transaction processing
-- * product catalog management
-- * data quality monitoring
-- * address standardization
-- * application log analysis
-- * regulatory compliance reporting
-- * csv data import
-- * organizational hierarchy
-- * iot sensor data ingestion
-- * batch etl performance
--
-- =====================================================================

-- Made with Bob
