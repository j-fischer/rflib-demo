@ECHO OFF

cd ..\rflib

call sfdx force:source:push -u rflib_demo

cd ..\rflib-demo

call sfdx force:source:push -f

call sfdx force:apex:execute -f apex\resetCustomSettings.apex

echo "Org is up-to-date"
