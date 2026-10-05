@ECHO OFF
SETLOCAL EnableExtensions

REM Creates a scratch org for the RFLIB demo and sets it up.
REM
REM Usage: scripts\orgInit.bat [--alias <alias>] [--packages]
REM
REM   --alias, -a <alias>  Alias of the new scratch org (default: rflib_demo)
REM   --packages           Install the latest released RFLIB packages instead of deploying the source code
REM                        of the sibling ..\rflib checkout
REM   --help, -h           Show this help
REM
REM By default, RFLIB (all of RFLIB, RFLIB-FS, RFLIB-TF and RFLIB-PHAROS) is deployed as unpackaged source
REM from ..\rflib, so that the org runs the RFLIB code under development. In this mode, the RFLIB SF CLI
REM plugin skips Flow fault paths, because they require RFLIB 11.4.0+ installed as a package. Use --packages
REM to demo them; the latest package version IDs are then read from the packageAliases in the RFLIB
REM sfdx-project.json (see scripts\lib\latestRflibPackage.js).
REM
REM Setup order (every step requires the ones before it):
REM   1. RFLIB                           Source: ..\rflib. Packages: RFLIB, RFLIB-FS, RFLIB-TF
REM   2. Pharos                          RFLIB-PHAROS forwards log events to the pharos__ objects
REM   3. RFLIB-PHAROS (--packages only)  Part of the source deploy in step 1 otherwise
REM   4. Big Object Utility
REM   5. RFLIB permission sets, demo source (its custom metadata uses RFLIB-FS and RFLIB-TF types)
REM   6. Apex scripts                    pharosPostInstall.apex requires RFLIB-PHAROS and Pharos

REM Resolve the repository root before parsing the arguments: SHIFT also shifts %0.
set "REPO_ROOT=%~dp0.."
for %%I in ("%REPO_ROOT%\..\rflib") do set "RFLIB_DIR=%%~fI"

REM Third-party AppExchange packages
set "PHAROS_PACKAGE_ID=04t5a000001g4x9AAA"
set "BIG_OBJECT_UTILITY_PACKAGE_ID=04t7F000003irldQAA"
set "INSTALL_WAIT_MINUTES=30"

set "ORG_ALIAS=rflib_demo"
set USE_PACKAGES=0

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--alias" goto opt_alias
if /I "%~1"=="-a" goto opt_alias
if /I "%~1"=="--packages" (set USE_PACKAGES=1& goto next_arg)
if /I "%~1"=="--help" goto usage
if /I "%~1"=="-h" goto usage
echo ERROR: Unknown option "%~1"
goto usage_error

:opt_alias
if "%~2"=="" (
    echo ERROR: %~1 requires an alias
    goto usage_error
)
set "ORG_ALIAS=%~2"
shift

:next_arg
shift
goto parse_args

:args_done
pushd "%REPO_ROOT%"

if %USE_PACKAGES%==1 (
    echo Resolving the latest RFLIB package versions
    call :resolve_package RFLIB RFLIB_ID || goto failed
    call :resolve_package RFLIB-FS RFLIB_FS_ID || goto failed
    call :resolve_package RFLIB-TF RFLIB_TF_ID || goto failed
    call :resolve_package RFLIB-PHAROS RFLIB_PHAROS_ID || goto failed
) else (
    if not exist "%RFLIB_DIR%\sfdx-project.json" (
        echo ERROR: No RFLIB checkout found in %RFLIB_DIR%. Clone https://github.com/j-fischer/rflib next to
        echo        this repository, or run with --packages to install the released RFLIB packages.
        goto failed
    )
)

echo Creating scratch org %ORG_ALIAS%
call sf org create scratch --alias %ORG_ALIAS% --set-default --definition-file config/project-scratch-def.json --duration-days 30
if errorlevel 1 goto failed

if %USE_PACKAGES%==1 (
    call :install_package "RFLIB %RFLIB_ID_VERSION%" %RFLIB_ID% || goto failed
    call :install_package "RFLIB-FS %RFLIB_FS_ID_VERSION%" %RFLIB_FS_ID% || goto failed
    call :install_package "RFLIB-TF %RFLIB_TF_ID_VERSION%" %RFLIB_TF_ID% || goto failed
) else (
    call :deploy_rflib_source || goto failed
)

call :install_package "Pharos" %PHAROS_PACKAGE_ID% || goto failed
if %USE_PACKAGES%==1 (
    call :install_package "RFLIB-PHAROS %RFLIB_PHAROS_ID_VERSION%" %RFLIB_PHAROS_ID% || goto failed
)
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

:usage
echo Usage: scripts\orgInit.bat [--alias ^<alias^>] [--packages]
echo.
echo   --alias, -a ^<alias^>  Alias of the new scratch org (default: rflib_demo)
echo   --packages           Install the latest released RFLIB packages instead of deploying the source code
echo                        of the sibling ..\rflib checkout. Required for Flow fault-path instrumentation.
exit /b 0

:usage_error
echo Run "scripts\orgInit.bat --help" for usage.
exit /b 1

REM Deploys all package directories of the ..\rflib checkout as unpackaged source.
:deploy_rflib_source
echo Deploying RFLIB source from %RFLIB_DIR%
pushd "%RFLIB_DIR%"
call sf project deploy start --target-org %ORG_ALIAS% --ignore-conflicts
if errorlevel 1 (
    popd
    echo ERROR: Deploying the RFLIB source failed
    exit /b 1
)
popd
exit /b 0

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
