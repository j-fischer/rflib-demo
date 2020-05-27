#!/bin/bash

sfdx force:org:create -a rflib_demo -s -f config/project-scratch-def.json -d 30

cd ../rflib

sfdx force:source:push -u rflib_demo
sfdx force:user:permset:assign -u rflib_demo -n rflib_Ops_Center_Access

cd ../rflib-demo

sfdx force:source:push
sfdx force:user:permset:assign -n dreamhouse

sfdx force:org:open -p /lightning/page/home
echo "Org is set up"
