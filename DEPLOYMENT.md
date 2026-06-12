# Db2 for z/OS JAR Deployment Guide

This guide explains how to build and automatically deploy the Db2_Routines JAR file to a Db2 for z/OS database using Maven.

## Overview

The project includes an automated deployment mechanism that:
1. Builds the JAR file with all dependencies
2. Connects to Db2 for z/OS via JDBC
3. Installs or replaces the JAR in the database
4. Refreshes the WLM environment
5. Commits the transaction

## Prerequisites

- Maven 3.6+ installed at: `C:\Users\UliSeelbach\OneDrive - IBM\Tools\apache-maven-3.9.14\bin`
- Java 8 or higher
- Network access to Db2 for z/OS system
- Valid Db2 credentials with INSTALL_JAR privileges
- Db2 JDBC driver (included as dependency)

## Configuration

### Default Properties

The `pom.xml` includes default deployment properties that can be overridden:

```xml
<db2.host>localhost</db2.host>
<db2.port>5045</db2.port>
<db2.database>DALLASD</db2.database>
<db2.user>db2admin</db2.user>
<db2.password></db2.password>
<db2.jar.id>MYSCHEMA.ROUTINES</db2.jar.id>
<db2.wlm.env>DBDGENVJ</db2.wlm.env>
```

### Externalizing Configuration

You can override these properties in several ways:

#### 1. Command Line Parameters (Recommended)

```bash
mvn clean install -Pdb2-deploy \
  -Ddb2.host=mainframe.company.com \
  -Ddb2.port=5045 \
  -Ddb2.database=PRODDB \
  -Ddb2.user=myuser \
  -Ddb2.password=mypassword \
  -Ddb2.jar.id=PRODSCHEMA.ROUTINES \
  -Ddb2.wlm.env=PRODWLM
```

#### 2. Maven Settings File (~/.m2/settings.xml)

```xml
<settings>
  <profiles>
    <profile>
      <id>db2-prod</id>
      <properties>
        <db2.host>mainframe.company.com</db2.host>
        <db2.port>5045</db2.port>
        <db2.database>PRODDB</db2.database>
        <db2.user>myuser</db2.user>
        <db2.password>mypassword</db2.password>
        <db2.jar.id>PRODSCHEMA.ROUTINES</db2.jar.id>
        <db2.wlm.env>PRODWLM</db2.wlm.env>
      </properties>
    </profile>
  </profiles>
</settings>
```

Then activate with: `mvn clean install -Pdb2-deploy,db2-prod`

#### 3. Environment Variables

Set environment variables and reference them:

```bash
export DB2_HOST=mainframe.company.com
export DB2_USER=myuser
export DB2_PASSWORD=mypassword

mvn clean install -Pdb2-deploy \
  -Ddb2.host=${DB2_HOST} \
  -Ddb2.user=${DB2_USER} \
  -Ddb2.password=${DB2_PASSWORD}
```

#### 4. Project-specific Properties File

Create a `deployment.properties` file (add to .gitignore):

```properties
db2.host=mainframe.company.com
db2.port=5045
db2.database=PRODDB
db2.user=myuser
db2.password=mypassword
db2.jar.id=PRODSCHEMA.ROUTINES
db2.wlm.env=PRODWLM
```

## Usage

### Basic Build (No Deployment)

Build the JAR without deploying:

```bash
mvn clean package
```

This creates:
- `target/Db2_Routines-0.0.1-SNAPSHOT.jar` (without dependencies)
- `target/routines.jar` (with all dependencies - use this for deployment)

### Build and Deploy

Build and automatically deploy to Db2:

```bash
mvn clean install -Pdb2-deploy \
  -Ddb2.host=your-host \
  -Ddb2.user=your-user \
  -Ddb2.password=your-password
```

### Manual Deployment

You can also deploy manually using the Deploy utility:

```bash
java -cp target/routines.jar com.ibm.db2.deploy.Deploy \
  --jdbc-url jdbc:db2://mainframe:5045/DALLASD \
  --user myuser \
  --password mypassword \
  --jar target/routines.jar \
  --id MYSCHEMA.ROUTINES \
  --wlm DBDGENVJ
```

## Deployment Process

The deployment follows this workflow:

1. **Build Phase** (`mvn package`)
   - Compiles Java sources
   - Runs unit tests
   - Creates JAR with dependencies

2. **Install Phase** (`mvn install` with `-Pdb2-deploy`)
   - Executes the Deploy utility
   - Connects to Db2 via JDBC
   - Attempts to replace existing JAR
   - If JAR doesn't exist, installs new JAR
   - Refreshes WLM environment
   - Commits transaction

3. **Output**
   ```
   Connecting to database...
     JDBC URL: jdbc:db2://mainframe:5045/DALLASD
     Username: myuser
   Connected successfully.
   
   Deploying JAR file...
     Local file: target/routines.jar
     Target ID:  MYSCHEMA.ROUTINES
     Attempting to replace existing JAR...
     JAR replaced successfully.
   
   Refreshing WLM environment: DBDGENVJ
     WLM environment refreshed successfully.
   
   Deployment completed successfully.
   Database connection closed.
   ```

## Common Scenarios

### Development Environment

```bash
mvn clean install -Pdb2-deploy \
  -Ddb2.host=dev-mainframe \
  -Ddb2.database=DEVDB \
  -Ddb2.user=devuser \
  -Ddb2.password=devpass \
  -Ddb2.jar.id=DEVSCHEMA.ROUTINES \
  -Ddb2.wlm.env=DEVWLM
```

### Production Deployment

```bash
mvn clean install -Pdb2-deploy \
  -Ddb2.host=prod-mainframe.company.com \
  -Ddb2.port=5045 \
  -Ddb2.database=PRODDB \
  -Ddb2.user=produser \
  -Ddb2.password=${PROD_PASSWORD} \
  -Ddb2.jar.id=PRODSCHEMA.ROUTINES \
  -Ddb2.wlm.env=PRODWLM
```

### CI/CD Pipeline

```yaml
# Example GitHub Actions workflow
- name: Build and Deploy to Db2
  run: |
    mvn clean install -Pdb2-deploy \
      -Ddb2.host=${{ secrets.DB2_HOST }} \
      -Ddb2.port=${{ secrets.DB2_PORT }} \
      -Ddb2.database=${{ secrets.DB2_DATABASE }} \
      -Ddb2.user=${{ secrets.DB2_USER }} \
      -Ddb2.password=${{ secrets.DB2_PASSWORD }} \
      -Ddb2.jar.id=${{ vars.DB2_JAR_ID }} \
      -Ddb2.wlm.env=${{ vars.DB2_WLM_ENV }}
```

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to Db2
```
ERROR: Database error: Connection refused
```

**Solutions**:
- Verify host and port are correct
- Check network connectivity: `ping mainframe-host`
- Ensure firewall allows connection on Db2 port
- Verify Db2 subsystem is active

### Authentication Errors

**Problem**: Invalid credentials
```
ERROR: Database error: Invalid authorization specification (SQLCODE: -551)
```

**Solutions**:
- Verify username and password
- Check user has INSTALL_JAR privilege
- Ensure user has access to target schema

### JAR Installation Errors

**Problem**: Cannot install JAR
```
ERROR: Database error: JAR already exists (SQLCODE: -20200)
```

**Solutions**:
- The utility automatically tries REPLACE first
- If manual intervention needed, remove JAR first:
  ```sql
  CALL SQLJ.REMOVE_JAR('SCHEMA.JARNAME', 0);
  ```

### WLM Refresh Issues

**Problem**: WLM refresh fails
```
Warning: WLM refresh returned code 4: Environment not found
```

**Solutions**:
- Verify WLM environment name is correct
- Check WLM environment is defined in Db2
- Ensure user has authority to refresh WLM

### Maven Path Issues (Windows)

**Problem**: Maven not found
```
'mvn' is not recognized as an internal or external command
```

**Solutions**:
- Use full path to Maven:
  ```bash
  C:\Users\UliSeelbach\OneDrive` -` IBM\Tools\apache-maven-3.9.14\bin\mvn.cmd clean install -Pdb2-deploy
  ```
- Or add Maven to PATH environment variable

## Security Best Practices

1. **Never commit passwords** to version control
2. **Use environment variables** for sensitive data
3. **Leverage Maven settings** with encrypted passwords
4. **Use CI/CD secrets** for automated deployments
5. **Rotate credentials** regularly
6. **Use least privilege** - grant only necessary permissions

## Advanced Configuration

### Custom Deployment Goal

Add a custom execution to run deployment separately:

```bash
mvn exec:java@deploy-to-db2 \
  -Ddb2.host=mainframe \
  -Ddb2.user=myuser \
  -Ddb2.password=mypass
```

### Skip Tests During Deployment

```bash
mvn clean install -Pdb2-deploy -DskipTests \
  -Ddb2.host=mainframe \
  -Ddb2.user=myuser \
  -Ddb2.password=mypass
```

### Verbose Logging

Enable debug output:

```bash
mvn clean install -Pdb2-deploy -X \
  -Ddb2.host=mainframe \
  -Ddb2.user=myuser \
  -Ddb2.password=mypass
```

## Exit Codes

The Deploy utility returns:
- **0**: Success
- **1**: Error (connection failure, invalid parameters, deployment error)

## Related Files

- [`pom.xml`](pom.xml) - Maven configuration with deployment profile
- [`src/main/java/com/ibm/db2/deploy/Deploy.java`](src/main/java/com/ibm/db2/deploy/Deploy.java) - Deployment utility
- [`README.adoc`](README.adoc) - Project documentation

## Support

For issues or questions:
1. Check this documentation
2. Review error messages and SQLCODE
3. Verify Db2 configuration and permissions
4. Check Maven and Java versions
5. Review Db2 for z/OS documentation

## Version History

- **1.0.0** - Initial automated deployment configuration
  - Maven profile for Db2 deployment
  - Externalized configuration properties
  - Automated JAR installation/replacement
  - WLM environment refresh
  - Comprehensive error handling