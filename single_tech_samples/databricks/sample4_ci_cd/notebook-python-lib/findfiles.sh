#!/bin/sh
for file in `databricks fs ls dbfs:/FileStore/jars --absolute`
do
    extension="${file##*.}"
    if [ $extension = "whl" ]
    then
        # databricks libraries install --cluster-id "0516-144506-pug503" --whl $file
        echo $file
    fi
done