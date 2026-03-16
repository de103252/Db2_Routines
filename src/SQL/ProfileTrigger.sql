-- ============================================================================
-- INSTEAD OF Trigger for DB2 Profile Management
-- ============================================================================
-- Purpose: Provides a view-based interface to insert/update profile data
--          in both SYSIBM.DSN_PROFILE_TABLE and SYSIBM.DSN_PROFILE_ATTRIBUTES
--
-- Author: Bob
-- Date: 2026-02-12
-- DB2 Version: DB2 for z/OS
-- ============================================================================
-- Actual DB2 z/OS Schema:
-- DSN_PROFILE_TABLE columns:
--   AUTHID, PLANNAME, COLLID, PKGNAME, LOCATION, PROFILEID, 
--   PROFILE_TIMESTAMP, PROFILE_ENABLED, GROUP_MEMBER, REMARKS, 
--   ROLE, PRDID, CLIENT_APPLNAME, CLIENT_USERID, CLIENT_WRKSTNNAME
--
-- DSN_PROFILE_ATTRIBUTES columns:
--   PROFILEID, KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3,
--   ATTRIBUTE_TIMESTAMP, REMARKS
-- ============================================================================

-- ============================================================================
-- Step 1: Create a view that combines both profile tables
-- ============================================================================
CREATE OR REPLACE VIEW PROFILE_VIEW AS
SELECT 
    P.AUTHID,
    P.PLANNAME,
    P.COLLID,
    P.PKGNAME,
    P.LOCATION,
    P.PROFILEID,
    P.PROFILE_TIMESTAMP,
    P.PROFILE_ENABLED,
    P.GROUP_MEMBER,
    P.REMARKS AS PROFILE_REMARKS,
    P.ROLE,
    P.PRDID,
    P.CLIENT_APPLNAME,
    P.CLIENT_USERID,
    P.CLIENT_WRKSTNNAME,
    A.KEYWORDS,
    A.ATTRIBUTE1,
    A.ATTRIBUTE2,
    A.ATTRIBUTE3,
    A.ATTRIBUTE_TIMESTAMP,
    A.REMARKS AS ATTRIBUTE_REMARKS
FROM 
    SYSIBM.DSN_PROFILE_TABLE P
LEFT JOIN 
    SYSIBM.DSN_PROFILE_ATTRIBUTES A
    ON P.PROFILEID = A.PROFILEID
;

-- ============================================================================
-- Step 2: Create INSTEAD OF trigger using MERGE statements
-- ============================================================================
CREATE OR REPLACE TRIGGER PROFILE_VIEW_IOT
INSTEAD OF INSERT ON PROFILE_VIEW
REFERENCING NEW AS N
FOR EACH ROW
BEGIN ATOMIC
    -- Merge into DSN_PROFILE_TABLE
    MERGE INTO SYSIBM.DSN_PROFILE_TABLE AS T
    USING (VALUES (
        N.AUTHID,
        N.PLANNAME,
        N.COLLID,
        N.PKGNAME,
        N.LOCATION,
        N.PROFILEID,
        COALESCE(N.PROFILE_TIMESTAMP, CURRENT TIMESTAMP),
        N.PROFILE_ENABLED,
        N.GROUP_MEMBER,
        N.PROFILE_REMARKS,
        N.ROLE,
        N.PRDID,
        N.CLIENT_APPLNAME,
        N.CLIENT_USERID,
        N.CLIENT_WRKSTNNAME
    )) AS S(AUTHID, PLANNAME, COLLID, PKGNAME, LOCATION, PROFILEID, 
            PROFILE_TIMESTAMP, PROFILE_ENABLED, GROUP_MEMBER, REMARKS, 
            ROLE, PRDID, CLIENT_APPLNAME, CLIENT_USERID, CLIENT_WRKSTNNAME)
    ON T.PROFILEID = S.PROFILEID
    WHEN MATCHED THEN
        UPDATE SET
            AUTHID = S.AUTHID,
            PLANNAME = S.PLANNAME,
            COLLID = S.COLLID,
            PKGNAME = S.PKGNAME,
            LOCATION = S.LOCATION,
            PROFILE_TIMESTAMP = CURRENT TIMESTAMP,
            PROFILE_ENABLED = S.PROFILE_ENABLED,
            GROUP_MEMBER = S.GROUP_MEMBER,
            REMARKS = S.REMARKS,
            ROLE = S.ROLE,
            PRDID = S.PRDID,
            CLIENT_APPLNAME = S.CLIENT_APPLNAME,
            CLIENT_USERID = S.CLIENT_USERID,
            CLIENT_WRKSTNNAME = S.CLIENT_WRKSTNNAME
    WHEN NOT MATCHED THEN
        INSERT (AUTHID, PLANNAME, COLLID, PKGNAME, LOCATION, PROFILEID, 
                PROFILE_TIMESTAMP, PROFILE_ENABLED, GROUP_MEMBER, REMARKS, 
                ROLE, PRDID, CLIENT_APPLNAME, CLIENT_USERID, CLIENT_WRKSTNNAME)
        VALUES (S.AUTHID, S.PLANNAME, S.COLLID, S.PKGNAME, S.LOCATION, S.PROFILEID, 
                S.PROFILE_TIMESTAMP, S.PROFILE_ENABLED, S.GROUP_MEMBER, S.REMARKS, 
                S.ROLE, S.PRDID, S.CLIENT_APPLNAME, S.CLIENT_USERID, S.CLIENT_WRKSTNNAME);
    
    -- Merge into DSN_PROFILE_ATTRIBUTES (only if keyword data is provided)
    IF N.KEYWORDS IS NOT NULL THEN
        MERGE INTO SYSIBM.DSN_PROFILE_ATTRIBUTES AS T
        USING (VALUES (
            N.PROFILEID,
            N.KEYWORDS,
            N.ATTRIBUTE1,
            N.ATTRIBUTE2,
            N.ATTRIBUTE3,
            COALESCE(N.ATTRIBUTE_TIMESTAMP, CURRENT TIMESTAMP),
            N.ATTRIBUTE_REMARKS
        )) AS S(PROFILEID, KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3,
                ATTRIBUTE_TIMESTAMP, REMARKS)
        ON T.PROFILEID = S.PROFILEID 
           AND T.KEYWORDS = S.KEYWORDS
        WHEN MATCHED THEN
            UPDATE SET
                ATTRIBUTE1 = S.ATTRIBUTE1,
                ATTRIBUTE2 = S.ATTRIBUTE2,
                ATTRIBUTE3 = S.ATTRIBUTE3,
                ATTRIBUTE_TIMESTAMP = CURRENT TIMESTAMP,
                REMARKS = S.REMARKS
        WHEN NOT MATCHED THEN
            INSERT (PROFILEID, KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3,
                    ATTRIBUTE_TIMESTAMP, REMARKS)
            VALUES (S.PROFILEID, S.KEYWORDS, S.ATTRIBUTE1, S.ATTRIBUTE2, S.ATTRIBUTE3,
                    S.ATTRIBUTE_TIMESTAMP, S.REMARKS);
    END IF;
END
;

-- ============================================================================
-- Alternative: INSTEAD OF trigger with explicit INSERT/UPDATE logic
-- ============================================================================
-- This version uses explicit EXISTS checks instead of MERGE
-- Uncomment if MERGE is not preferred or causes issues

/*
CREATE OR REPLACE TRIGGER PROFILE_VIEW_IOT_ALT
INSTEAD OF INSERT ON PROFILE_VIEW
REFERENCING NEW AS N
FOR EACH ROW
BEGIN ATOMIC
    DECLARE V_EXISTS INT DEFAULT 0;
    
    -- Check if profile exists
    SELECT COUNT(*) INTO V_EXISTS
    FROM SYSIBM.DSN_PROFILE_TABLE
    WHERE PROFILEID = N.PROFILEID;
    
    -- Insert or Update DSN_PROFILE_TABLE
    IF V_EXISTS = 0 THEN
        INSERT INTO SYSIBM.DSN_PROFILE_TABLE 
            (AUTHID, PLANNAME, COLLID, PKGNAME, LOCATION, PROFILEID, 
             PROFILE_TIMESTAMP, PROFILE_ENABLED, GROUP_MEMBER, REMARKS, 
             ROLE, PRDID, CLIENT_APPLNAME, CLIENT_USERID, CLIENT_WRKSTNNAME)
        VALUES 
            (N.AUTHID, N.PLANNAME, N.COLLID, N.PKGNAME, N.LOCATION, N.PROFILEID,
             COALESCE(N.PROFILE_TIMESTAMP, CURRENT TIMESTAMP), N.PROFILE_ENABLED, 
             N.GROUP_MEMBER, N.PROFILE_REMARKS, N.ROLE, N.PRDID, N.CLIENT_APPLNAME, 
             N.CLIENT_USERID, N.CLIENT_WRKSTNNAME);
    ELSE
        UPDATE SYSIBM.DSN_PROFILE_TABLE
        SET AUTHID = N.AUTHID,
            PLANNAME = N.PLANNAME,
            COLLID = N.COLLID,
            PKGNAME = N.PKGNAME,
            LOCATION = N.LOCATION,
            PROFILE_TIMESTAMP = CURRENT TIMESTAMP,
            PROFILE_ENABLED = N.PROFILE_ENABLED,
            GROUP_MEMBER = N.GROUP_MEMBER,
            REMARKS = N.PROFILE_REMARKS,
            ROLE = N.ROLE,
            PRDID = N.PRDID,
            CLIENT_APPLNAME = N.CLIENT_APPLNAME,
            CLIENT_USERID = N.CLIENT_USERID,
            CLIENT_WRKSTNNAME = N.CLIENT_WRKSTNNAME
        WHERE PROFILEID = N.PROFILEID;
    END IF;
    
    -- Handle attributes if provided
    IF N.KEYWORDS IS NOT NULL THEN
        SET V_EXISTS = 0;
        
        -- Check if attribute exists
        SELECT COUNT(*) INTO V_EXISTS
        FROM SYSIBM.DSN_PROFILE_ATTRIBUTES
        WHERE PROFILEID = N.PROFILEID
          AND KEYWORDS = N.KEYWORDS;
        
        -- Insert or Update DSN_PROFILE_ATTRIBUTES
        IF V_EXISTS = 0 THEN
            INSERT INTO SYSIBM.DSN_PROFILE_ATTRIBUTES
                (PROFILEID, KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3,
                 ATTRIBUTE_TIMESTAMP, REMARKS)
            VALUES
                (N.PROFILEID, N.KEYWORDS, N.ATTRIBUTE1, N.ATTRIBUTE2, N.ATTRIBUTE3,
                 COALESCE(N.ATTRIBUTE_TIMESTAMP, CURRENT TIMESTAMP), N.ATTRIBUTE_REMARKS);
        ELSE
            UPDATE SYSIBM.DSN_PROFILE_ATTRIBUTES
            SET ATTRIBUTE1 = N.ATTRIBUTE1,
                ATTRIBUTE2 = N.ATTRIBUTE2,
                ATTRIBUTE3 = N.ATTRIBUTE3,
                ATTRIBUTE_TIMESTAMP = CURRENT TIMESTAMP,
                REMARKS = N.ATTRIBUTE_REMARKS
            WHERE PROFILEID = N.PROFILEID
              AND KEYWORDS = N.KEYWORDS;
        END IF;
    END IF;
END
;
*/

-- ============================================================================
-- Usage Examples
-- ============================================================================

-- Example 1: Insert a new profile for a specific plan
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, PROFILE_REMARKS)
VALUES 
    ('PROF001', 'USER001', 'MYPLAN', 'Y', 'Development profile');
*/

-- Example 2: Insert a profile with collection and package information
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, COLLID, PKGNAME, PROFILE_ENABLED, PROFILE_REMARKS)
VALUES 
    ('PROF002', 'USER002', 'PLAN2', 'COLL1', 'PKG1', 'Y', 'Production profile');
*/

-- Example 3: Insert a profile with attributes
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE_REMARKS)
VALUES 
    ('PROF003', 'USER003', 'PLAN3', 'Y', 
     'MAXCONN', '100', 'TIMEOUT', '3600', 'Connection settings');
*/

-- Example 4: Update an existing profile
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, PROFILE_REMARKS)
VALUES 
    ('PROF001', 'USER001', 'MYPLAN', 'N', 'Disabled for maintenance');
*/

-- Example 5: Add client information to a profile
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     CLIENT_APPLNAME, CLIENT_USERID, CLIENT_WRKSTNNAME)
VALUES 
    ('PROF004', 'USER004', 'PLAN4', 'Y', 
     'MYAPP', 'APPUSER', 'WKST001');
*/

-- Example 6: Profile with role and group membership
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     ROLE, GROUP_MEMBER, PROFILE_REMARKS)
VALUES 
    ('PROF005', 'USER005', 'PLAN5', 'Y', 
     'ADMIN', 'DBADMINS', 'Administrator profile');
*/

-- Example 7: Profile with location and product ID
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     LOCATION, PRDID)
VALUES 
    ('PROF006', 'USER006', 'PLAN6', 'Y', 
     'REMOTE1', 'DSN12015');
*/

-- Example 8: Update profile attributes with remarks
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE_REMARKS)
VALUES 
    ('PROF003', 'USER003', 'PLAN3', 'Y', 
     'MAXCONN', '200', 'TIMEOUT', '7200', 'Updated connection limits');
*/

-- Example 9: Add new keyword to existing profile
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, 
     KEYWORDS, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE_REMARKS)
VALUES 
    ('PROF003', 'USER003', 'PLAN3', 'Y', 
     'SECURITY', 'HIGH', 'AUDIT', 'Security settings');
*/

-- Example 10: Profile with both profile and attribute remarks
/*
INSERT INTO PROFILE_VIEW 
    (PROFILEID, AUTHID, PLANNAME, PROFILE_ENABLED, PROFILE_REMARKS,
     KEYWORDS, ATTRIBUTE1, ATTRIBUTE_REMARKS)
VALUES 
    ('PROF007', 'USER007', 'PLAN7', 'Y', 'Test profile',
     'PRIORITY', 'HIGH', 'High priority processing');
*/

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Check profiles
/*
SELECT * FROM SYSIBM.DSN_PROFILE_TABLE
ORDER BY PROFILEID;
*/

-- Check attributes
/*
SELECT * FROM SYSIBM.DSN_PROFILE_ATTRIBUTES
ORDER BY PROFILEID, KEYWORDS;
*/

-- Check combined view
/*
SELECT * FROM PROFILE_VIEW
ORDER BY PROFILEID, KEYWORDS;
*/

-- Check specific profile with all attributes
/*
SELECT * FROM PROFILE_VIEW
WHERE PROFILEID = 'PROF003'
ORDER BY KEYWORDS;
*/

-- Check profiles with their attribute counts
/*
SELECT P.PROFILEID, P.AUTHID, P.PLANNAME, P.PROFILE_ENABLED,
       COUNT(A.KEYWORDS) AS ATTRIBUTE_COUNT
FROM SYSIBM.DSN_PROFILE_TABLE P
LEFT JOIN SYSIBM.DSN_PROFILE_ATTRIBUTES A ON P.PROFILEID = A.PROFILEID
GROUP BY P.PROFILEID, P.AUTHID, P.PLANNAME, P.PROFILE_ENABLED
ORDER BY P.PROFILEID;
*/

-- ============================================================================
-- Notes
-- ============================================================================
-- 1. PROFILEID is the primary key for DSN_PROFILE_TABLE
-- 2. PROFILE_TIMESTAMP is automatically set to CURRENT TIMESTAMP on insert/update
-- 3. ATTRIBUTE_TIMESTAMP is automatically set to CURRENT TIMESTAMP on insert/update
-- 4. PROFILE_ENABLED typically uses 'Y' or 'N' values
-- 5. PLANNAME, COLLID, PKGNAME identify the DB2 plan/package
-- 6. LOCATION identifies remote DB2 locations
-- 7. CLIENT_* columns store client application information
-- 8. ROLE and GROUP_MEMBER support authorization management
-- 9. Both tables have REMARKS columns (aliased as PROFILE_REMARKS and ATTRIBUTE_REMARKS in view)
-- 10. KEYWORDS in DSN_PROFILE_ATTRIBUTES acts as a category identifier
-- 11. Up to 3 attribute values can be stored per keyword
-- 12. Multiple keyword rows can exist for the same PROFILEID
-- 13. The MERGE approach automatically handles INSERT vs UPDATE
-- 14. Both tables are updated atomically within the trigger
-- 15. Timestamps are managed automatically but can be overridden on insert
-- ============================================================================

-- Made with Bob
