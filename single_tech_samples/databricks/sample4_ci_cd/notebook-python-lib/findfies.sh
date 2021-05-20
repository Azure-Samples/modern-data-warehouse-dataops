#!/bin/sh
for file in `databricks fs ls dbfs:/FileStore/jars --absolute`
do
    extension="${file##*.}"
    if [ $extension = "whl" ];
    then
        echo $file
    fi
done