@ECHO OFF

call sf org create scratch -a rflib_demo -d -f config/project-scratch-def.json -y 30

cd ..\rflib

call sf project deploy start -o rflib_demo --ignore-conflicts
call sf org assign permset -o rflib_demo -n rflib_Ops_Center_Access
call sf org assign permset -o rflib_demo -n rflib_Enable_Client_Logging
call sf org assign permset -o rflib_demo -n rflib_Create_Application_Event

cd ..\rflib-demo

call sf project deploy start --ignore-conflicts
call sf org assign permset -n dreamhouse

call sf apex run -f apex\resetCustomSettings.apex
call sf apex run -f apex\pharosPostInstall.apex

call sf org open -p /lightning/page/home

echo "Installing Pharos"
call sf package install --package 04t5a000001g4x9AAA -o rflib_demo -w 10

echo "Installing Big Object Utility"
call sf package install --package 04t7F000003irldQAA -o rflib_demo -w 10

echo "Installing Big Steaming Monitor"
call sf package install --package 04t1t000003Po3QAAS -o rflib_demo -w 10 && sf org assign permset --name Streaming_Monitor -o rflib_demo

call sf project reset tracking -p

echo "Org is set up"
