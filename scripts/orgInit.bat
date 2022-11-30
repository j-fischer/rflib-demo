@ECHO OFF

call sfdx force:org:create -a rflib_demo -s -f config/project-scratch-def.json -d 30

cd ..\rflib

call sfdx force:source:push -u rflib_demo
call sfdx force:user:permset:assign -u rflib_demo -n rflib_Ops_Center_Access
call sfdx force:user:permset:assign -u rflib_demo -n rflib_Enable_Client_Logging

cd ..\rflib-demo

call sfdx force:source:push
call sfdx force:user:permset:assign -n dreamhouse

call sfdx force:apex:execute -f apex\resetCustomSettings.apex

call sfdx force:org:open -p /lightning/page/home

echo "Installing Big Object Utility"
call sfdx force:package:install --package 04t7F000003irldQAA -u rflib_demo -w 10

call sfdx force:source:tracking:reset -p

echo "Org is set up"
