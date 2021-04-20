#!/bin/bash

for package in $(ls */*.buildlog | sed -e "s/\.buildlog$//")
do
	compgen -G "$package-*.tbz2" > /dev/null || echo $package

done
