# DB2 Profile Management INSTEAD OF Trigger Implementation

## Overview

This implementation provides an INSTEAD OF trigger for DB2 for z/OS that simplifies the management of profile data across two system tables:
- `SYSIBM.DSN_PROFILE_TABLE` - Main profile information
- `SYSIBM.DSN_PROFILE_ATTRIBUTES` - Profile attributes with keyword-based storage

## Actual DB2 z/OS Schema

### DSN_PROFILE_TABLE
The actual columns in SYSIBM.DSN_PROFILE_TABLE are:

- **AUTHID**: Authorization ID
- **PLANNAME**: DB2 plan name
- **COLLID**: Collection ID
- **PKGNAME**: Package name
- **LOCATION**: Remote location name
- **PROFILEID**: Profile identifier (primary key)
- **PROFILE_TIMESTAMP**: Timestamp of profile creation/update
- **PROFILE_ENABLED**: Profile enabled flag ('Y' or 'N')
- **GROUP_MEMBER**: Group membership
- **REMARKS**: Profile remarks/description
- **ROLE**: Role name
- **PRDID**: Product ID
- **CLIENT_APPLNAME**: Client application name
- **CLIENT_USERID**: Client user ID
- **CLIENT_WRKSTNNAME**: Client workstation name

### DSN_PROFILE_ATTRIBUTES
- **PROFILEID**: Profile identifier (foreign key)
- **KEYWORDS**: Keyword/attribute category name
- **ATTRIBUTE1**: First attribute value
- **ATTRIBUTE2**: Second attribute value
- **ATTRIBUTE3**: Third attribute value
- **Composite key**: (PROFILEID, KEYWORDS)

## Solution Approach

The solution uses **MERGE statements** within an INSTEAD OF trigger to automatically determine whether to INSERT or UPDATE rows based on whether corresponding records already exist.

## Components

### 1. View: PROFILE_VIEW
A unified view that combines both profile tables using a LEFT JOIN, providing a single interface for data manipulation.

```sql
CREATE OR REPLACE VIEW PROFILE_VIEW AS
SELECT 
    P.AUTHID, P.PLANNAME, P.COLLID, P.PKGNAME, P.LOCATION, P.PROFILEID,
    P.PROFILE_TIMESTAMP, P.PROFILE_ENABLED, P.GROUP_MEMBER, P.REMARKS,
    P.ROLE, P.PRDID, P.CLIENT_APPLNAME, P.CLIENT_USERID, P.CLIENT_WRKSTNNAME,
    A.KEYWORDS, A.ATTRIBUTE1, A.ATTRIBUTE2, A.ATTRIBUTE3
FROM 
    SYSIBM.DSN_PROFILE_TABLE P
LEFT JOIN 
    SYSIBM.DSN_PROFILE_ATTRIBUTES A
    ON P.PROFILEID = A.PROFILEID;
```

### 2. Trigger: PROFILE_VIEW_IOT
An INSTEAD OF INSERT trigger that:
- Uses MERGE to upsert data into `DSN_PROFILE_TABLE`
- Uses MERGE to upsert data into `DSN_PROFILE_ATTRIBUTES` (when KEYWORDS is provided)
- Automatically handles INSERT vs UPDATE logic based on existing data
- Updates PROFILE_TIMESTAMP to CURRENT TIMESTAMP on every operation

### 3. Alternative Trigger: PROFILE_VIEW_IOT_ALT (Commented)
An alternative implementation using explicit EXISTS checks and conditional INSERT/UPDATE statements instead of MERGE.

## Key Features

### Automatic Insert/Update Detection
The MERGE statement automatically determines whether to INSERT or UPDATE based on PROFILEID:
```sql
MERGE INTO SYSIBM.DSN_PROFILE_TABLE AS T
USING (VALUES (...)) AS S(...)
ON T.PROFILEID = S.PROFILEID
WHEN MATCHED THEN UPDATE ...
WHEN NOT MATCHED THEN INSERT ...
```

### Timestamp Management
- `PROFILE_TIMESTAMP`: Set to CURRENT TIMESTAMP on both insert and update operations
- Uses COALESCE to allow explicit timestamp on insert, defaults to CURRENT TIMESTAMP

### Optional Attributes
The trigger intelligently handles profiles with or without attributes:
- If `KEYWORDS` IS NULL, only the profile table is updated
- If `KEYWORDS` IS NOT NULL, both tables are updated

### Composite Key Handling
For attributes, the MERGE uses a composite key:
```sql
ON T.PROFILEID = S.PROFILEID 
   AND T.KEYWORDS = S.KEYWORDS
```

### Multiple Attribute Values
Each keyword can store up to 3 attribute values (ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3), allowing for flexible data storage.

## Usage Scenarios

### Scenario 1: Create New Profile for a Plan
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED)
VALUES 
    ('PROF001', 'USER001', 'MYPLAN', 'Y');
```
**Result**: INSERT into DSN_PROFILE_TABLE

### Scenario 2: Profile with Collection and Package
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, COLLID, PKGNAME, PROFILE_ENABLED, REMARKS)
VALUES 
    ('PROF002', 'USER002', 'PLAN2', 'COLL1', 'PKG1', 'Y', 'Production profile');
```
**Result**: INSERT into DSN_PROFILE_TABLE with collection/package info

### Scenario 3: Profile with Attributes
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3)
VALUES 
    ('PROF003', 'USER003', 'PLAN3', 'Y', 
     'MAXCONN', '100', 'TIMEOUT', '3600');
```
**Result**: INSERT into both DSN_PROFILE_TABLE and DSN_PROFILE_ATTRIBUTES

### Scenario 4: Update Existing Profile
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, REMARKS)
VALUES 
    ('PROF001', 'USER001', 'MYPLAN', 'N', 'Disabled for maintenance');
```
**Result**: UPDATE DSN_PROFILE_TABLE (MERGE detects existing PROFILEID)

### Scenario 5: Profile with Client Information
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     CLIENT_APPLNAME, CLIENT_USERID, CLIENT_WRKSTNNAME)
VALUES 
    ('PROF004', 'USER004', 'PLAN4', 'Y', 
     'MYAPP', 'APPUSER', 'WKST001');
```
**Result**: INSERT with client tracking information

### Scenario 6: Profile with Role and Group
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     ROLE, GROUP_MEMBER)
VALUES 
    ('PROF005', 'USER005', 'PLAN5', 'Y', 
     'ADMIN', 'DBADMINS');
```
**Result**: INSERT with authorization information

### Scenario 7: Profile with Remote Location
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     LOCATION, PRDID)
VALUES 
    ('PROF006', 'USER006', 'PLAN6', 'Y', 
     'REMOTE1', 'DSN12015');
```
**Result**: INSERT with remote location and product ID

### Scenario 8: Update Profile Attributes
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3)
VALUES 
    ('PROF003', 'USER003', 'PLAN3', 'Y', 
     'MAXCONN', '200', 'TIMEOUT', '7200');
```
**Result**: UPDATE DSN_PROFILE_TABLE, UPDATE DSN_PROFILE_ATTRIBUTES

### Scenario 9: Add New Keyword to Existing Profile
```sql
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     KEYWORDS, ATTRIBUTE1, ATTRIBUTE2)
VALUES 
    ('PROF003', 'USER003', 'PLAN3', 'Y', 
     'SECURITY', 'HIGH', 'AUDIT');
```
**Result**: UPDATE DSN_PROFILE_TABLE, INSERT into DSN_PROFILE_ATTRIBUTES

## Column Usage Guide

### Profile Identification
- **PROFILEID**: Unique identifier for the profile (required)
- **AUTHID**: Authorization ID associated with the profile

### Plan/Package Identification
- **PLANNAME**: DB2 plan name
- **COLLID**: Collection ID for packages
- **PKGNAME**: Package name
- **LOCATION**: Remote DB2 location name

### Profile Control
- **PROFILE_ENABLED**: 'Y' to enable, 'N' to disable
- **PROFILE_TIMESTAMP**: Automatically managed by trigger

### Authorization
- **ROLE**: Role name for role-based access
- **GROUP_MEMBER**: Group membership information

### Client Tracking
- **CLIENT_APPLNAME**: Application name
- **CLIENT_USERID**: User ID from client
- **CLIENT_WRKSTNNAME**: Workstation name

### Metadata
- **REMARKS**: Free-form description or notes
- **PRDID**: Product identifier (e.g., DSN12015 for DB2 12)

### Attributes (DSN_PROFILE_ATTRIBUTES)
- **KEYWORDS**: Category or type of attributes
- **ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3**: Up to 3 values per keyword

## Technical Details

### MERGE vs Explicit INSERT/UPDATE

**MERGE Advantages:**
- More concise code
- Single statement handles both INSERT and UPDATE
- Better performance (single table scan)
- Atomic operation
- Standard SQL syntax

**Explicit INSERT/UPDATE Advantages:**
- More explicit control flow
- Easier to debug
- May be required for older DB2 versions
- Can add custom logic between operations

### DB2 for z/OS Compatibility

This implementation is designed for:
- **DB2 for z/OS V10+** (MERGE statement support)
- **DB2 for z/OS V9+** (INSTEAD OF trigger support)

For older versions, use the alternative implementation with explicit INSERT/UPDATE logic.

### Transaction Handling

The trigger uses `BEGIN ATOMIC`, which means:
- All operations within the trigger are atomic
- If any operation fails, all changes are rolled back
- No explicit COMMIT is needed within the trigger

### Performance Considerations

1. **MERGE Performance**: MERGE is generally more efficient than separate EXISTS check + INSERT/UPDATE
2. **Index Requirements**: Ensure proper indexes exist on:
   - `DSN_PROFILE_TABLE.PROFILEID` (primary key)
   - `DSN_PROFILE_ATTRIBUTES.PROFILEID, KEYWORDS` (composite key)
3. **Trigger Overhead**: INSTEAD OF triggers add overhead; use judiciously

## Attribute Storage Pattern

The DSN_PROFILE_ATTRIBUTES table uses a keyword-based storage pattern:
- Each row represents a keyword category
- Up to 3 related values can be stored per keyword
- Multiple keywords can exist for the same profile

**Example:**
```
PROFILEID | KEYWORDS  | ATTRIBUTE1 | ATTRIBUTE2 | ATTRIBUTE3
----------|-----------|------------|------------|------------
PROF001   | MAXCONN   | 100        | TIMEOUT    | 3600
PROF001   | SECURITY  | HIGH       | AUDIT      | YES
PROF001   | PRIORITY  | 5          | NULL       | NULL
```

## Error Handling

The trigger will fail if:
- Required columns (PROFILEID) are NULL
- Data type mismatches occur
- Constraint violations occur in target tables
- Insufficient privileges to modify target tables
- PROFILE_ENABLED contains values other than 'Y' or 'N' (if constrained)

## Security Considerations

1. **Privileges Required**:
   - SELECT on PROFILE_VIEW
   - INSERT on PROFILE_VIEW (which translates to INSERT/UPDATE on base tables)
   - The trigger executes with the definer's privileges

2. **Audit Trail**:
   - PROFILE_TIMESTAMP provides basic audit information
   - Consider adding trigger audit logging for production use

## Maintenance

### Modifying the Trigger
```sql
DROP TRIGGER PROFILE_VIEW_IOT;
-- Then recreate with new logic
```

### Disabling the Trigger
```sql
ALTER TRIGGER PROFILE_VIEW_IOT DISABLE;
```

### Enabling the Trigger
```sql
ALTER TRIGGER PROFILE_VIEW_IOT ENABLE;
```

### Viewing Trigger Definition
```sql
SELECT * FROM SYSIBM.SYSTRIGGERS
WHERE NAME = 'PROFILE_VIEW_IOT';
```

## Testing Recommendations

1. **Test Insert Operations**:
   - New profile with minimal columns (PROFILEID, AUTHID, PLANNAME)
   - Profile with all columns populated
   - Profile with attributes
   - Multiple keywords for same profile

2. **Test Update Operations**:
   - Update existing profile
   - Update existing keyword attributes
   - Add new keyword to existing profile
   - Enable/disable profiles

3. **Test Edge Cases**:
   - NULL values in optional columns
   - Very long values in text columns
   - Special characters in names
   - Concurrent updates

4. **Performance Testing**:
   - Bulk inserts
   - High-frequency updates
   - Large attribute sets

## Troubleshooting

### Common Issues

**Issue**: Trigger not firing
- **Solution**: Verify trigger is enabled and view exists

**Issue**: Permission denied
- **Solution**: Grant necessary privileges on base tables

**Issue**: Duplicate key errors
- **Solution**: Check for concurrent transactions or application logic issues

**Issue**: Performance degradation
- **Solution**: Review indexes, consider batch operations

## Alternative Approaches

### 1. Stored Procedure
```sql
CREATE PROCEDURE UPSERT_PROFILE(...)
-- Explicit MERGE or INSERT/UPDATE logic
```

### 2. Application Logic
Handle INSERT/UPDATE logic in the application layer for more control

### 3. ETL Tool
Use DB2 utilities or ETL tools for batch operations

## Conclusion

This INSTEAD OF trigger implementation provides a clean, efficient interface for managing DB2 profile data across multiple tables. The MERGE-based approach is recommended for DB2 z/OS V10+ environments.

The implementation correctly uses the actual DB2 z/OS schema with all 15 columns in DSN_PROFILE_TABLE and the keyword-based attribute storage in DSN_PROFILE_ATTRIBUTES.

## Files

- **src/SQL/ProfileTrigger.sql**: Complete implementation with both MERGE and explicit versions
- **PROFILE_TRIGGER_IMPLEMENTATION.md**: This documentation file

## References

- IBM DB2 for z/OS SQL Reference
- IBM DB2 for z/OS Application Programming and SQL Guide
- DB2 Profile Tables Documentation
- DB2 Trigger Best Practices