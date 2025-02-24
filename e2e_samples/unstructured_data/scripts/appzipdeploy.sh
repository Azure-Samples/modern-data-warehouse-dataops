#!/bin/bash

## Usage
# ./appzipdeploy.sh <resource_group> <app_service_name>
# ./appzipdeploy.sh <resource_group> <app_service_name> <file_path>

# Access command-line arguments
if [ -z "$1" ]; then
    echo "Please provide resource group"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Please provide app service name"
    exit 1
fi

RESOURCE_GROUP=$1
APP_SERVICE_NAME=$2
FILE_PATH=${3:-"./appdeploy.zip"}

#### RUN this script from the Excitation repo client Directory.
TARGET_DIR="client"
CURRENT_DIR=$(basename "$PWD")

if [ "$CURRENT_DIR" == "$TARGET_DIR" ]; then
    echo "You are in correct directory: $CURRENT_DIR"
else
    echo "expected directory to be: $TARGET_DIR"
    echo "Currently in: $CURRENT_DIR"
    exit 1
fi

# Zip the project
rm -rf ./dist/
rm -rf $FILE_PATH

#Alternative to tar.
# zip -r $FILE_PATH . -x "node_modules/*"
echo "current directory:" $(pwd)

npm install
npm run build

tar --exclude="./node_modules/*" \
    --exclude="*.env" -acf $FILE_PATH ./*

#### ------------------------------------- #######
# Upload the zip for deployment directly from local (old Kudo Deploy, soon to be deprecated)
# az webapp deployment source config-zip --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME --src $FILE_PATH

# New AZ deploy way(Unclear if the build artifacts can be ignored)
az webapp deploy --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME --src-path $FILE_PATH --type zip --async true --track-status false

if [ $? -eq 0 ]; then
    echo "Web App Deployment completed successfully."
else
    echo "Web App Zip Deployment failed"
    exit 1
fi
