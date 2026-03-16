# Security Policy

## Supported Versions

This project supports the following Db2 for z/OS versions:

| Db2 Version | Supported          |
| ----------- | ------------------ |
| 13.x        | :white_check_mark: |
| 12.x        | :white_check_mark: |
| 11.x        | :warning: Limited  |
| < 11.x      | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

### How to Report

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. Email the maintainers directly with details
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 1 week
- **Status Updates**: Every 2 weeks until resolved
- **Resolution**: Depends on severity and complexity

## Security Best Practices

### For Developers

#### 1. Never Hardcode Credentials

**BAD:**
```java
Connection c = DriverManager.getConnection(
    "jdbc:db2://server:5045/DB", "username", "password");
```

**GOOD:**
```java
// Use environment variables
String url = System.getenv("DB2_URL");
String user = System.getenv("DB2_USER");
String password = System.getenv("DB2_PASSWORD");
Connection c = DriverManager.getConnection(url, user, password);
```

#### 2. Validate All Inputs

Always validate and sanitize inputs to prevent SQL injection and other attacks:

```sql
create function safe_function(input varchar(100))
  returns integer
begin
  -- Validate input
  if input is null then
    signal sqlstate '22004';
  end if;
  
  if length(input) > 100 then
    signal sqlstate '22001';
  end if;
  
  -- Process validated input
  return process(input);
end
```

#### 3. Use Parameterized Queries

When building dynamic SQL, always use parameter markers:

```java
// GOOD - Uses parameter markers
PreparedStatement ps = conn.prepareStatement(
    "SELECT * FROM table WHERE id = ?");
ps.setInt(1, userId);

// BAD - String concatenation (SQL injection risk)
Statement s = conn.createStatement();
s.executeQuery("SELECT * FROM table WHERE id = " + userId);
```

#### 4. Implement Proper Error Handling

Don't expose sensitive information in error messages:

```java
try {
    // operation
} catch (SQLException e) {
    // BAD - Exposes internal details
    throw new SQLException("Database error: " + e.getMessage());
    
    // GOOD - Generic message, log details separately
    logger.error("Database operation failed", e);
    throw new SQLException("Operation failed", "58030");
}
```

#### 5. Use Least Privilege Principle

- Grant only necessary permissions to function execution
- Use `SECURITY USER` clause when appropriate
- Avoid `SECURITY DEFINER` unless absolutely necessary

### For Deployment

#### 1. Secure JAR Installation

When installing Java functions:

```sql
-- Use appropriate security settings
CALL SQLJ.DB2_INSTALL_JAR(
    'file:///path/to/routines.jar',
    'SCHEMA.JARNAME',
    0  -- Do not replace if exists
);

-- Grant execute only to authorized users
GRANT EXECUTE ON FUNCTION schema.function_name TO authorized_role;
```

#### 2. WLM Environment Security

- Configure WLM environments with appropriate security settings
- Use separate WLM environments for different security levels
- Restrict STEPLIB access to authorized libraries only
- Enable WLM environment security features

#### 3. Protect Load Libraries

For C and COBOL functions:
- Place load modules in APF-authorized libraries only when necessary
- Restrict write access to load libraries
- Use RACF or equivalent to control access
- Regularly audit library contents

#### 4. Secure Configuration Files

- Store configuration files outside web-accessible directories
- Use appropriate file permissions (e.g., 600 for sensitive files)
- Encrypt sensitive configuration data
- Use z/OS security features (RACF, encryption services)

### For Users

#### 1. Review Function Definitions

Before using external functions, review their definitions:

```sql
-- Check function security settings
SELECT NAME, SCHEMA, SECURITY, EXTERNAL_ACTION
  FROM SYSIBM.SYSROUTINES
 WHERE SCHEMA = 'SYSFUN'
   AND NAME = 'FUNCTION_NAME';
```

#### 2. Understand Function Behavior

- Read documentation thoroughly
- Understand what data the function accesses
- Know what external actions it performs
- Be aware of performance implications

#### 3. Use Appropriate Grants

Grant function execution privileges carefully:

```sql
-- Grant to specific users
GRANT EXECUTE ON FUNCTION sysfun.my_function TO user1, user2;

-- Grant to roles (preferred)
GRANT EXECUTE ON FUNCTION sysfun.my_function TO app_role;
```

#### 4. Monitor Function Usage

Regularly audit function usage:

```sql
-- Check function execution in accounting records
-- Review WLM environment logs
-- Monitor for unusual patterns
```

## Known Security Considerations

### 1. SUBMIT Function

The `SUBMIT` and `SUBMIT_T` functions submit JCL to the internal reader:

- **Risk**: Potential for unauthorized job submission
- **Mitigation**: 
  - Grant execute privilege only to authorized users
  - Validate JCL content before submission
  - Monitor submitted jobs
  - Use RACF to control job submission authority

### 2. READ_GENERIC_FILE Function

Reads data from z/OS datasets:

- **Risk**: Potential unauthorized data access
- **Mitigation**:
  - Function runs with user's authority (SECURITY USER)
  - RACF controls dataset access
  - Validate file paths
  - Audit file access

### 3. External Java Functions

Java functions can access system resources:

- **Risk**: Potential for unauthorized system access
- **Mitigation**:
  - Use Java security manager
  - Configure WLM environment with appropriate security
  - Review Java code before deployment
  - Use signed JARs when possible

### 4. Regular Expression Functions

Regex functions can be vulnerable to ReDoS (Regular Expression Denial of Service):

- **Risk**: Complex patterns can cause excessive CPU usage
- **Mitigation**:
  - Pattern caching limits impact
  - Set appropriate ASUTIME limits
  - Monitor function execution times
  - Validate patterns before use

## Security Checklist for New Functions

Before deploying a new function:

- [ ] No hardcoded credentials or sensitive data
- [ ] Input validation implemented
- [ ] Proper error handling (no information leakage)
- [ ] Appropriate security clause (USER vs DEFINER)
- [ ] External actions documented
- [ ] Resource usage limits considered
- [ ] Access control requirements documented
- [ ] Security testing completed
- [ ] Code review performed
- [ ] Documentation includes security notes

## Compliance

This project aims to comply with:

- IBM Db2 for z/OS security best practices
- z/OS security standards
- General secure coding principles

## Updates

This security policy is reviewed and updated regularly. Last update: 2026-02-08

## Contact

For security concerns or questions:
- Review this document first
- Check existing documentation
- Contact maintainers for sensitive issues

## Acknowledgments

We appreciate responsible disclosure of security vulnerabilities and will acknowledge contributors (with permission) in our security advisories.