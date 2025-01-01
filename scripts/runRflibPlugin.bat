REM filepath: /c:/Users/fisch/Projects/Salesforce/rflib-demo/scripts/runRflibPlugin.bat
@ECHO OFF

set PRETTIER=0
if "%1"=="--prettier" set PRETTIER=1

echo "Setting logging settings"
set DEBUG=sf:RflibLoggingApexInstrument

echo "Resetting git"
call git reset --hard

echo "Running Apex instrumentation"
if %PRETTIER%==1 (
    call sf rflib logging apex instrument --sourcepath force-app/main/default/classes --prettier
    call sf rflib logging aura instrument --sourcepath force-app/main/default/aura --prettier
    call sf rflib logging lwc instrument --sourcepath force-app/main/default/lwc --prettier
) else (
    call sf rflib logging apex instrument --sourcepath force-app/main/default/classes
    call sf rflib logging aura instrument --sourcepath force-app/main/default/aura
    call sf rflib logging lwc instrument --sourcepath force-app/main/default/lwc
)