@ECHO OFF
SETLOCAL EnableExtensions

REM Brings an org created with scripts\orgInit.bat up to date.
REM
REM Usage: scripts\updateOrg.bat [org alias]   (default: rflib_demo)
REM
REM Upgrades the installed RFLIB packages to their latest versions with "sf rflib packages upgrade"
REM and deploys the demo source. Orgs created by older versions of orgInit, which deployed RFLIB as
REM unpackaged source, have no RFLIB packages to upgrade; recreate them with scripts\orgInit.bat.

set "MIN_PLUGIN_VERSION=0.21.0"
set "INSTALL_WAIT_MINUTES=30"

set "ORG_ALIAS=rflib_demo"
if not "%~1"=="" set "ORG_ALIAS=%~1"

pushd "%~dp0.."

call node scripts\lib\checkPluginVersion.js %MIN_PLUGIN_VERSION%
if errorlevel 1 goto failed

echo Upgrading the RFLIB packages
call sf rflib packages upgrade --target-org %ORG_ALIAS% --no-prompt --wait %INSTALL_WAIT_MINUTES%
if errorlevel 1 goto failed

echo Deploying the demo source
call sf project deploy start --target-org %ORG_ALIAS% --ignore-conflicts
if errorlevel 1 goto failed

call sf apex run --target-org %ORG_ALIAS% --file apex\resetCustomSettings.apex
if errorlevel 1 goto failed

call sf project reset tracking --target-org %ORG_ALIAS% --no-prompt
if errorlevel 1 goto failed

popd
echo Org %ORG_ALIAS% is up-to-date
exit /b 0

:failed
popd
echo ERROR: Org update stopped because the previous step failed.
exit /b 1
