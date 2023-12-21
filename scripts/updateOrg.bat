@ECHO OFF

cd ..\rflib

call sf project deploy start -o rflib_demo --ignore-conflicts

cd ..\rflib-demo

call sf project deploy start --ignore-conflicts

call sf apex run -f apex\resetCustomSettings.apex

call sf project reset tracking -p

echo "Org is up-to-date"
