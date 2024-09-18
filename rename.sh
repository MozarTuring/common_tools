#!/bin/bash
cd $1
echo $1
cfilelist=$(ls)
B=".mp4"
for cfilename in $cfilelist
do
    if [[ $cfilename != *$B ]]
    then
        mv $cfilename ${cfilename}$'.mp4'
    fi
done