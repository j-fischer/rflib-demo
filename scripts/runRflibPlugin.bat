@ECHO OFF
SETLOCAL EnableExtensions

REM Instruments the demo source in force-app with the RFLIB SF CLI plugin (rflib-plugin).
REM
REM Usage: scripts\runRflibPlugin.bat [options]
REM
REM   --target-org, -o <alias>  Org the instrumented Flows will be deployed to (default: rflib_demo).
REM                             Fault paths are only instrumented if it has RFLIB 11.4.0+ installed as a package.
REM   --prettier                Format the instrumented Apex, Aura and LWC files with Prettier
REM   --debug                   Enable debug output of the plugin
REM   --skip-reset              Do not run "git reset --hard" before instrumenting
REM   --skip-instrumented       Skip files that already contain RFLIB logging
REM   --skip-fault-paths        Do not add error logging to Flow fault paths
REM   --dryrun                  Preview the changes without modifying any files (implies --skip-reset)
REM   --help, -h                Show this help
REM
REM WARNING: Unless --skip-reset or --dryrun is passed, all uncommitted changes are discarded with "git reset --hard".

REM Resolve the repository root before parsing the arguments: SHIFT also shifts %0.
set "REPO_ROOT=%~dp0.."
set "MIN_PLUGIN_VERSION=0.21.0"
set "TARGET_ORG=rflib_demo"
set PRETTIER=0
set DEBUG_MODE=0
set SKIP_RESET=0
set SKIP_INSTRUMENTED=0
set SKIP_FAULT_PATHS=0
set DRYRUN=0

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--target-org" goto opt_target_org
if /I "%~1"=="-o" goto opt_target_org
if /I "%~1"=="--prettier" (set PRETTIER=1& goto next_arg)
if /I "%~1"=="--debug" (set DEBUG_MODE=1& goto next_arg)
if /I "%~1"=="--skip-reset" (set SKIP_RESET=1& goto next_arg)
if /I "%~1"=="--skip-instrumented" (set SKIP_INSTRUMENTED=1& goto next_arg)
if /I "%~1"=="--skip-fault-paths" (set SKIP_FAULT_PATHS=1& goto next_arg)
if /I "%~1"=="--dryrun" (set DRYRUN=1& goto next_arg)
if /I "%~1"=="--help" goto usage
if /I "%~1"=="-h" goto usage
echo ERROR: Unknown option "%~1"
goto usage_error

:opt_target_org
if "%~2"=="" (
    echo ERROR: %~1 requires an org alias or username
    goto usage_error
)
set "TARGET_ORG=%~2"
shift

:next_arg
shift
goto parse_args

:args_done
pushd "%REPO_ROOT%"

echo Checking rflib-plugin version
call node scripts\lib\checkPluginVersion.js %MIN_PLUGIN_VERSION%
if errorlevel 1 goto failed

if %DEBUG_MODE%==1 (
    echo Enabling debug output
    set SF_LOG_LEVEL=debug
    set DEBUG=sf:Rflib*
)

if %DRYRUN%==1 set SKIP_RESET=1
if %SKIP_RESET%==0 (
    echo Resetting git: discarding all uncommitted changes
    call git reset --hard
    if errorlevel 1 goto failed
)

set "COMMON_ARGS=--sourcepath force-app"
if %SKIP_INSTRUMENTED%==1 set "COMMON_ARGS=%COMMON_ARGS% --skip-instrumented"
if %DRYRUN%==1 set "COMMON_ARGS=%COMMON_ARGS% --dryrun --verbose"

set "CODE_ARGS=%COMMON_ARGS%"
if %PRETTIER%==1 set "CODE_ARGS=%CODE_ARGS% --prettier"

set "FLOW_ARGS=%COMMON_ARGS% --target-org %TARGET_ORG%"
if %SKIP_FAULT_PATHS%==1 set "FLOW_ARGS=%FLOW_ARGS% --skip-fault-paths"

echo Running Apex instrumentation
call sf rflib logging apex instrument %CODE_ARGS%
if errorlevel 1 goto failed

echo Running Aura instrumentation
call sf rflib logging aura instrument %CODE_ARGS%
if errorlevel 1 goto failed

echo Running LWC instrumentation
call sf rflib logging lwc instrument %CODE_ARGS%
if errorlevel 1 goto failed

echo Running Flow instrumentation against org %TARGET_ORG%
call sf rflib logging flow instrument %FLOW_ARGS%
if errorlevel 1 goto failed

popd
echo Instrumentation complete. Review the changes with "git diff" before deploying.
exit /b 0

:failed
popd
echo ERROR: Instrumentation stopped because the previous step failed.
exit /b 1

:usage
echo Usage: scripts\runRflibPlugin.bat [--target-org ^<alias^>] [--prettier] [--debug] [--skip-reset]
echo                                   [--skip-instrumented] [--skip-fault-paths] [--dryrun]
echo.
echo   --target-org, -o ^<alias^>  Org the instrumented Flows will be deployed to (default: rflib_demo)
echo   --prettier                Format the instrumented Apex, Aura and LWC files with Prettier
echo   --debug                   Enable debug output of the plugin
echo   --skip-reset              Do not run "git reset --hard" before instrumenting
echo   --skip-instrumented       Skip files that already contain RFLIB logging
echo   --skip-fault-paths        Do not add error logging to Flow fault paths
echo   --dryrun                  Preview the changes without modifying any files (implies --skip-reset)
exit /b 0

:usage_error
echo Run "scripts\runRflibPlugin.bat --help" for usage.
exit /b 1
