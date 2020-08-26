@ECHO OFF

call sfdx force:org:create -a rflib_demo -s -f config/project-scratch-def.json -d 30

cd ..\rflib

call sfdx force:source:push -u rflib_demo
call sfdx force:user:permset:assign -u rflib_demo -n rflib_Ops_Center_Access
call sfdx force:user:permset:assign -u rflib_demo -n rflib_Enable_Client_Logging

cd ..\rflib-demo

call sfdx force:source:push
call sfdx force:user:permset:assign -n dreamhouse

call sfdx force:org:open -p /lightning/page/home
echo "Org is set up"
