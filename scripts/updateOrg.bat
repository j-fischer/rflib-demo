@ECHO OFF
SETLOCAL EnableExtensions

REM Brings an org created with scripts\orgInit.bat up to date.
REM
REM Usage: scripts\updateOrg.bat [--target-org <alias>] [--packages]
REM
REM   --target-org, -o <alias>  Org to update (default: rflib_demo)
REM   --packages                Upgrade the installed RFLIB packages with "sf rflib packages upgrade" instead of
REM                             deploying the source code of the sibling ..\rflib checkout. Use this for orgs
REM                             created with "orgInit.bat --packages".
REM   --help, -h                Show this help
REM
REM Then deploys the demo source, resets the RFLIB Logger Settings and resets source tracking.

REM Resolve the repository root before parsing the arguments: SHIFT also shifts %0.
set "REPO_ROOT=%~dp0.."
for %%I in ("%REPO_ROOT%\..\rflib") do set "RFLIB_DIR=%%~fI"
set "MIN_PLUGIN_VERSION=0.21.0"
set "INSTALL_WAIT_MINUTES=30"

set "ORG_ALIAS=rflib_demo"
set USE_PACKAGES=0

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--target-org" goto opt_target_org
if /I "%~1"=="-o" goto opt_target_org
if /I "%~1"=="--packages" (set USE_PACKAGES=1& goto next_arg)
if /I "%~1"=="--help" goto usage
if /I "%~1"=="-h" goto usage
echo ERROR: Unknown option "%~1"
goto usage_error

:opt_target_org
if "%~2"=="" (
    echo ERROR: %~1 requires an org alias or username
    goto usage_error
)
set "ORG_ALIAS=%~2"
shift

:next_arg
shift
goto parse_args

:args_done
pushd "%REPO_ROOT%"

if %USE_PACKAGES%==1 goto upgrade_packages

if not exist "%RFLIB_DIR%\sfdx-project.json" (
    echo ERROR: No RFLIB checkout found in %RFLIB_DIR%. Run with --packages for orgs using the RFLIB packages.
    goto failed
)
echo Deploying RFLIB source from %RFLIB_DIR%
pushd "%RFLIB_DIR%"
call sf project deploy start --target-org %ORG_ALIAS% --ignore-conflicts
if errorlevel 1 (
    popd
    goto failed
)
popd
goto deploy_demo

:upgrade_packages
call node scripts\lib\checkPluginVersion.js %MIN_PLUGIN_VERSION%
if errorlevel 1 goto failed

echo Upgrading the RFLIB packages
call sf rflib packages upgrade --target-org %ORG_ALIAS% --no-prompt --wait %INSTALL_WAIT_MINUTES%
if errorlevel 1 goto failed

:deploy_demo
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

:usage
echo Usage: scripts\updateOrg.bat [--target-org ^<alias^>] [--packages]
echo.
echo   --target-org, -o ^<alias^>  Org to update (default: rflib_demo)
echo   --packages                Upgrade the installed RFLIB packages instead of deploying the ..\rflib source
exit /b 0

:usage_error
echo Run "scripts\updateOrg.bat --help" for usage.
exit /b 1
