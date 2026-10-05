@ECHO OFF
SETLOCAL EnableExtensions

REM Creates a scratch org for the RFLIB demo and sets it up.
REM
REM Usage: scripts\orgInit.bat [org alias]   (default: rflib_demo)
REM
REM The RFLIB packages are installed as unlocked packages, so that the RFLIB SF CLI plugin can detect
REM RFLIB 11.4.0+ in the org and instrument Flow fault paths. The latest package version IDs are read
REM from the packageAliases in the RFLIB sfdx-project.json (see scripts\lib\latestRflibPackage.js), which
REM is taken from a sibling ..\rflib checkout if present, or from GitHub otherwise.
REM
REM Setup order (every step requires the ones before it):
REM   1. RFLIB, RFLIB-FS, RFLIB-TF       RFLIB-TF 4.0.0 requires RFLIB 10.0.0+ and RFLIB-FS 4.0.0+
REM   2. Pharos, then RFLIB-PHAROS       RFLIB-PHAROS forwards log events to the pharos__ objects
REM   3. Big Object Utility
REM   4. Demo source                     Its custom metadata records use RFLIB-FS and RFLIB-TF types
REM   5. Permission sets and Apex scripts (pharosPostInstall.apex requires RFLIB-PHAROS)

REM Third-party AppExchange packages
set "PHAROS_PACKAGE_ID=04t5a000001g4x9AAA"
set "BIG_OBJECT_UTILITY_PACKAGE_ID=04t7F000003irldQAA"
set "INSTALL_WAIT_MINUTES=30"

set "ORG_ALIAS=rflib_demo"
if not "%~1"=="" set "ORG_ALIAS=%~1"

pushd "%~dp0.."

echo Resolving the latest RFLIB package versions
call :resolve_package RFLIB RFLIB_ID || goto failed
call :resolve_package RFLIB-FS RFLIB_FS_ID || goto failed
call :resolve_package RFLIB-TF RFLIB_TF_ID || goto failed
call :resolve_package RFLIB-PHAROS RFLIB_PHAROS_ID || goto failed

echo Creating scratch org %ORG_ALIAS%
call sf org create scratch --alias %ORG_ALIAS% --set-default --definition-file config/project-scratch-def.json --duration-days 30
if errorlevel 1 goto failed

call :install_package "RFLIB %RFLIB_ID_VERSION%" %RFLIB_ID% || goto failed
call :install_package "RFLIB-FS %RFLIB_FS_ID_VERSION%" %RFLIB_FS_ID% || goto failed
call :install_package "RFLIB-TF %RFLIB_TF_ID_VERSION%" %RFLIB_TF_ID% || goto failed
call :install_package "Pharos" %PHAROS_PACKAGE_ID% || goto failed
call :install_package "RFLIB-PHAROS %RFLIB_PHAROS_ID_VERSION%" %RFLIB_PHAROS_ID% || goto failed
call :install_package "Big Object Utility" %BIG_OBJECT_UTILITY_PACKAGE_ID% || goto failed

echo Assigning RFLIB permission sets
call sf org assign permset --target-org %ORG_ALIAS% --name rflib_Ops_Center_Access --name rflib_Enable_Client_Logging --name rflib_Create_Application_Event
if errorlevel 1 goto failed

echo Deploying the demo source
call sf project deploy start --target-org %ORG_ALIAS% --ignore-conflicts
if errorlevel 1 goto failed

call sf org assign permset --target-org %ORG_ALIAS% --name dreamhouse
if errorlevel 1 goto failed

echo Configuring RFLIB Logger Settings
call sf apex run --target-org %ORG_ALIAS% --file apex\resetCustomSettings.apex
if errorlevel 1 goto failed
call sf apex run --target-org %ORG_ALIAS% --file apex\pharosPostInstall.apex
if errorlevel 1 goto failed

call sf project reset tracking --target-org %ORG_ALIAS% --no-prompt
if errorlevel 1 goto failed

call sf org open --target-org %ORG_ALIAS% --path /lightning/page/home

popd
echo Org %ORG_ALIAS% is set up
exit /b 0

:failed
popd
echo ERROR: Org setup stopped because the previous step failed.
exit /b 1

REM Sets <variable> to the latest package version ID of <package name> and <variable>_VERSION to its version.
REM Usage: call :resolve_package <package name> <variable>
:resolve_package
set "%~2="
for /f "tokens=1,2" %%a in ('node scripts\lib\latestRflibPackage.js %~1') do (
    set "%~2=%%a"
    set "%~2_VERSION=%%b"
    echo   %~1 %%b: %%a
)
if not defined %~2 (
    echo ERROR: Unable to resolve the latest version of package %~1
    exit /b 1
)
exit /b 0

REM Usage: call :install_package "<display name>" <package version ID>
:install_package
echo Installing %~1 (%~2)
call sf package install --package %~2 --target-org %ORG_ALIAS% --wait %INSTALL_WAIT_MINUTES% --no-prompt
if errorlevel 1 (
    echo ERROR: Installing %~1 failed
    exit /b 1
)
exit /b 0
