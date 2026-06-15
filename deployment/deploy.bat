@echo off
REM ============================================================================
REM Db2 for z/OS JAR Deployment Script
REM ============================================================================
REM This script simplifies the Maven deployment process by providing
REM environment-specific deployment configurations.
REM
REM Usage:
REM   deploy.bat [environment] [options]
REM
REM Environments:
REM   dev   - Development environment
REM   test  - Test environment
REM   prod  - Production environment
REM
REM Options:
REM   --skip-tests    Skip unit tests during build
REM   --clean         Perform clean build
REM   --verbose       Enable verbose Maven output
REM ============================================================================

setlocal enabledelayedexpansion

REM Maven installation path
set MAVEN_HOME=C:\Users\UliSeelbach\OneDrive - IBM\Tools\apache-maven-3.9.14
set MVN_CMD=%MAVEN_HOME%\bin\mvn.cmd

REM Default Maven options
set MVN_OPTS=clean install -Pdb2-deploy
set SKIP_TESTS=
set VERBOSE=

REM Parse command line arguments
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" (
    echo ERROR: Environment not specified
    echo.
    goto :usage
)

shift
:parse_args
if "%1"=="" goto :end_parse
if "%1"=="--skip-tests" set SKIP_TESTS=-DskipTests
if "%1"=="--clean" set MVN_OPTS=clean install -Pdb2-deploy
if "%1"=="--verbose" set VERBOSE=-X
shift
goto :parse_args
:end_parse

REM Environment-specific configurations
if /i "%ENVIRONMENT%"=="dev" goto :dev_config
if /i "%ENVIRONMENT%"=="test" goto :test_config
if /i "%ENVIRONMENT%"=="prod" goto :prod_config

echo ERROR: Unknown environment '%ENVIRONMENT%'
echo.
goto :usage

:dev_config
echo ============================================================================
echo Deploying to DEVELOPMENT environment
echo ============================================================================
set DB2_HOST=dev-mainframe
set DB2_PORT=5045
set DB2_DATABASE=DEVDB
set DB2_USER=devuser
set DB2_JAR_ID=DEVSCHEMA.ROUTINES
set DB2_WLM_ENV=DEVWLM
goto :deploy

:test_config
echo ============================================================================
echo Deploying to TEST environment
echo ============================================================================
set DB2_HOST=test-mainframe
set DB2_PORT=5045
set DB2_DATABASE=TESTDB
set DB2_USER=testuser
set DB2_JAR_ID=TESTSCHEMA.ROUTINES
set DB2_WLM_ENV=TESTWLM
goto :deploy

:prod_config
echo ============================================================================
echo Deploying to PRODUCTION environment
echo ============================================================================
echo WARNING: You are about to deploy to PRODUCTION!
echo.
set /p CONFIRM="Type 'YES' to continue: "
if /i not "%CONFIRM%"=="YES" (
    echo Deployment cancelled.
    exit /b 1
)
set DB2_HOST=prod-mainframe.company.com
set DB2_PORT=5045
set DB2_DATABASE=PRODDB
set DB2_USER=produser
set DB2_JAR_ID=PRODSCHEMA.ROUTINES
set DB2_WLM_ENV=PRODWLM
goto :deploy

:deploy
REM Prompt for password (not echoed)
echo.
set /p DB2_PASSWORD="Enter Db2 password for %DB2_USER%: "
echo.

REM Display configuration
echo Configuration:
echo   Host:     %DB2_HOST%:%DB2_PORT%
echo   Database: %DB2_DATABASE%
echo   User:     %DB2_USER%
echo   JAR ID:   %DB2_JAR_ID%
echo   WLM Env:  %DB2_WLM_ENV%
echo.

REM Execute Maven build and deployment
echo Starting Maven build and deployment...
echo.

"%MVN_CMD%" %MVN_OPTS% %SKIP_TESTS% %VERBOSE% ^
    -Ddb2.host=%DB2_HOST% ^
    -Ddb2.port=%DB2_PORT% ^
    -Ddb2.database=%DB2_DATABASE% ^
    -Ddb2.user=%DB2_USER% ^
    -Ddb2.password=%DB2_PASSWORD% ^
    -Ddb2.jar.id=%DB2_JAR_ID% ^
    -Ddb2.wlm.env=%DB2_WLM_ENV%

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================================
    echo Deployment completed successfully!
    echo ============================================================================
    exit /b 0
) else (
    echo.
    echo ============================================================================
    echo Deployment FAILED! Check error messages above.
    echo ============================================================================
    exit /b 1
)

:usage
echo Usage: deploy.bat [environment] [options]
echo.
echo Environments:
echo   dev   - Development environment
echo   test  - Test environment
echo   prod  - Production environment
echo.
echo Options:
echo   --skip-tests    Skip unit tests during build
echo   --clean         Perform clean build
echo   --verbose       Enable verbose Maven output
echo.
echo Examples:
echo   deploy.bat dev
echo   deploy.bat test --skip-tests
echo   deploy.bat prod --clean --verbose
echo.
exit /b 1

@REM Made with Bob
