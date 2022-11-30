@ECHO OFF

cd ..\rflib

call sfdx force:source:push -u rflib_demo -f

cd ..\rflib-demo

call sfdx force:source:push -f

call sfdx force:apex:execute -f apex\resetCustomSettings.apex

call sfdx force:source:tracking:reset -p

echo "Org is up-to-date"
