@ECHO OFF

echo "Setting logging settings"
set DEBUG=sf:RflibLoggingApexInstrument

echo "Resetting git"
call git reset --hard

echo "Running Apex instrumentation"
call sf rflib logging apex instrument --sourcepath force-app/main/default/classes