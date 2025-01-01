REM filepath: /c:/Users/fisch/Projects/Salesforce/rflib-demo/scripts/runRflibPlugin.bat
@ECHO OFF

set PRETTIER=0
if "%1"=="--prettier" set PRETTIER=1

echo "Setting logging settings"
set SF_LOG_LEVEL=debug
set DEBUG=sf:Rflib*

echo "Resetting git"
call git reset --hard

echo "Running Apex instrumentation"
if %PRETTIER%==1 (
    call sf rflib logging apex instrument --sourcepath force-app --prettier
    call sf rflib logging aura instrument --sourcepath force-app --prettier
    call sf rflib logging lwc instrument --sourcepath force-app --prettier
) else (
    call sf rflib logging apex instrument --sourcepath force-app
    call sf rflib logging aura instrument --sourcepath force-app
    call sf rflib logging lwc instrument --sourcepath force-app
)