#!/bin/bash

path=$(pwd)
mkdir "$path/src"
mkdir "$path/src/master"
git clone --single-branch --branch master git@github.com:odoo/support-tools.git
cd src/master/
for i in "odoo" "enterprise" "design-themes"
do
	git clone --single-branch --branch master "git@github.com:odoo/$i.git"
done
cd ../../
