# Quick Start: Automated Db2 Deployment

This guide gets you deploying to Db2 for z/OS in 5 minutes.

## Prerequisites

✅ Maven installed at: `C:\Users\UliSeelbach\OneDrive - IBM\Tools\apache-maven-3.9.14\bin`  
✅ Java 8+  
✅ Db2 for z/OS access  
✅ Valid credentials with INSTALL_JAR privileges

## Option 1: Simple Command Line (Fastest)

```bash
# Windows - Use full Maven path
C:\Users\UliSeelbach\OneDrive` -` IBM\Tools\apache-maven-3.9.14\bin\mvn.cmd clean install -Pdb2-deploy ^
  -Ddb2.host=your-mainframe ^
  -Ddb2.port=5045 ^
  -Ddb2.database=YOURDB ^
  -Ddb2.user=youruser ^
  -Ddb2.password=yourpassword ^
  -Ddb2.jar.id=YOURSCHEMA.ROUTINES ^
  -Ddb2.wlm.env=YOURWLM
```

## Option 2: Using Deployment Script (Recommended)

```bash
# Edit deploy.bat to configure your environments
# Then run:
deploy.bat dev
```

The script will:
1. Prompt for your password (secure)
2. Build the JAR
3. Deploy to Db2
4. Refresh WLM environment

## Option 3: Using Maven Settings (Most Secure)

1. Copy template to Maven settings:
   ```bash
   copy settings.xml.template %USERPROFILE%\.m2\settings.xml
   ```

2. Edit `%USERPROFILE%\.m2\settings.xml` with your credentials

3. Deploy:
   ```bash
   mvn clean install -Pdb2-deploy,db2-dev
   ```

## What Happens During Deployment?

```
[1/5] 🔨 Building JAR with dependencies...
[2/5] 🔌 Connecting to Db2 for z/OS...
[3/5] 📦 Installing/Replacing JAR in database...
[4/5] 🔄 Refreshing WLM environment...
[5/5] ✅ Deployment complete!
```

## Configuration Properties

| Property | Description | Example |
|----------|-------------|---------|
| `db2.host` | Db2 hostname | `mainframe.company.com` |
| `db2.port` | Db2 port | `5045` |
| `db2.database` | Database name | `DALLASD` |
| `db2.user` | Username | `myuser` |
| `db2.password` | Password | `mypassword` |
| `db2.jar.id` | JAR identifier | `MYSCHEMA.ROUTINES` |
| `db2.wlm.env` | WLM environment | `DBDGENVJ` |

## Common Commands

### Build Only (No Deploy)
```bash
mvn clean package
```

### Deploy with Verbose Output
```bash
mvn clean install -Pdb2-deploy -X -Ddb2.host=... -Ddb2.user=... -Ddb2.password=...
```

### Skip Tests
```bash
mvn clean install -Pdb2-deploy -DskipTests -Ddb2.host=... -Ddb2.user=... -Ddb2.password=...
```

### Manual Deployment (Using Built JAR)
```bash
java -cp target/routines.jar com.ibm.db2.deploy.Deploy ^
  --jdbc-url jdbc:db2://host:port/database ^
  --user myuser ^
  --password mypassword ^
  --jar target/routines.jar ^
  --id SCHEMA.JARNAME ^
  --wlm WLMENV
```

## Troubleshooting

### ❌ "mvn not recognized"
**Solution**: Use full Maven path:
```bash
C:\Users\UliSeelbach\OneDrive` -` IBM\Tools\apache-maven-3.9.14\bin\mvn.cmd
```

### ❌ "Connection refused"
**Solution**: Check host, port, and network connectivity

### ❌ "Invalid authorization"
**Solution**: Verify credentials and INSTALL_JAR privilege

### ❌ "JAR not found"
**Solution**: Run `mvn package` first to build the JAR

## Security Best Practices

🔒 **Never commit passwords to Git**  
🔒 **Use environment variables for CI/CD**  
🔒 **Protect Maven settings.xml** (chmod 600)  
🔒 **Use encrypted passwords in Maven**  
🔒 **Rotate credentials regularly**

## Next Steps

📖 Read full documentation: [`DEPLOYMENT.md`](DEPLOYMENT.md)  
🔧 Customize deployment script: [`deploy.bat`](deploy.bat)  
⚙️ Configure Maven settings: [`settings.xml.template`](settings.xml.template)  
💻 Review Deploy utility: [`src/main/java/com/ibm/db2/deploy/Deploy.java`](src/main/java/com/ibm/db2/deploy/Deploy.java)

## Example: Complete Workflow

```bash
# 1. Build and test locally
mvn clean test

# 2. Deploy to development
deploy.bat dev

# 3. Verify deployment
# Connect to Db2 and run:
# SELECT * FROM SYSIBM.SYSJAROBJECTS WHERE JARNAME = 'ROUTINES';

# 4. Test your stored procedures
# CALL YOURSCHEMA.YOUR_PROCEDURE(...);

# 5. Deploy to production (with confirmation)
deploy.bat prod
```

## Support

For detailed information, see:
- [`DEPLOYMENT.md`](DEPLOYMENT.md) - Complete deployment guide
- [`README.adoc`](README.adoc) - Project documentation
- [`pom.xml`](pom.xml) - Maven configuration

---

**Ready to deploy?** Run: `deploy.bat dev` or use the Maven command above! 🚀