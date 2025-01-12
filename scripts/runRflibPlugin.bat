@ECHO OFF

REM Usage: runRflibPlugin.bat [--prettier] [--debug] [--skip-reset] [--skip-instrumented]

set PRETTIER=0
set DEBUG_MODE=0
set SKIP_RESET=0
set SKIP_INSTRUMENTED=0
if "%1"=="--prettier" set PRETTIER=1
if "%2"=="--prettier" set PRETTIER=1
if "%3"=="--prettier" set PRETTIER=1
if "%4"=="--prettier" set PRETTIER=1
if "%1"=="--debug" set DEBUG_MODE=1
if "%2"=="--debug" set DEBUG_MODE=1
if "%3"=="--debug" set DEBUG_MODE=1
if "%4"=="--debug" set DEBUG_MODE=1
if "%1"=="--skip-reset" set SKIP_RESET=1
if "%2"=="--skip-reset" set SKIP_RESET=1
if "%3"=="--skip-reset" set SKIP_RESET=1
if "%4"=="--skip-reset" set SKIP_RESET=1
if "%1"=="--skip-instrumented" set SKIP_INSTRUMENTED=1
if "%2"=="--skip-instrumented" set SKIP_INSTRUMENTED=1
if "%3"=="--skip-instrumented" set SKIP_INSTRUMENTED=1
if "%4"=="--skip-instrumented" set SKIP_INSTRUMENTED=1

echo "Setting logging settings"
if %DEBUG_MODE%==1 (
    set SF_LOG_LEVEL=debug
    set DEBUG=sf:Rflib*
)

if %SKIP_RESET%==0 (
    echo "Resetting git"
    call git reset --hard
)

echo "Running Apex instrumentation"
if %PRETTIER%==1 (
    if %SKIP_INSTRUMENTED%==1 (
        call sf rflib logging apex instrument --sourcepath force-app --prettier --skip-instrumented
        call sf rflib logging aura instrument --sourcepath force-app --prettier --skip-instrumented
        call sf rflib logging lwc instrument --sourcepath force-app --prettier --skip-instrumented
    ) else (
        call sf rflib logging apex instrument --sourcepath force-app --prettier
        call sf rflib logging aura instrument --sourcepath force-app --prettier
        call sf rflib logging lwc instrument --sourcepath force-app --prettier
    )
) else (
    if %SKIP_INSTRUMENTED%==1 (
        call sf rflib logging apex instrument --sourcepath force-app --skip-instrumented
        call sf rflib logging aura instrument --sourcepath force-app --skip-instrumented
        call sf rflib logging lwc instrument --sourcepath force-app --skip-instrumented
    ) else (
        call sf rflib logging apex instrument --sourcepath force-app
        call sf rflib logging aura instrument --sourcepath force-app
        call sf rflib logging lwc instrument --sourcepath force-app
    )
)