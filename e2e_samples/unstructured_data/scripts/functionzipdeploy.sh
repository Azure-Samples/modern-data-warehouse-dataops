#!/bin/bash
# This script is used to deploy a function app to Azure Functions using a zip package.
# utility: ./functionzipdeploy.sh <subscription_id> <resource_group> <function_app_name> <storage_account>

# Variables
SUBSCRIPTION_ID=$1
RESOURCE_GROUP=$2
FUNCTION_APP=$3
STORAGE_ACCOUNT=$4
CONTAINER_NAME=$FUNCTION_APP

# Generate a file name based on the current date-time epoch
EPOCH_TIME=$(date +%s)
BLOB_NAME="deploy-${EPOCH_TIME}.zip"

# Build the project
rm -rf dist/
rm -rf deploy.zip

npm install
npm run build

tar --exclude="node_modules/azure-functions-core-tools/*" \
    --exclude="node_modules/typescript/*" \
    --exclude="node_modules/@types/*" \
    --exclude="infra/*" -a -c -f ./deploy.zip ./*

az functionapp deployment source config-zip -g $RESOURCE_GROUP -n $FUNCTION_APP --src ./deploy.zip

# # Create the storage container
# az storage container create --name $FUNCTION_APP --account-name $STORAGE_ACCOUNT

# # Upload zip file to Azure Blob Storage
# az storage blob upload \
#     --account-name $STORAGE_ACCOUNT \
#     --container-name $FUNCTION_APP \
#     --name $BLOB_NAME \
#     --file ./deploy.zip \
#     --overwrite

# # Construct the SAS URL
# BLOB_URL="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER_NAME}/${BLOB_NAME}"

# echo "BLOB URL: $BLOB_URL"

# # Set the WEBSITE_RUN_FROM_PACKAGE app setting to the deployment package SAS URL
# az functionapp config appsettings set -g $RESOURCE_GROUP -n $FUNCTION_APP --settings WEBSITE_RUN_FROM_PACKAGE=$BLOB_URL

# # Sync the function triggers
# az rest \
#     --method post \
#     --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$FUNCTION_APP/syncfunctiontriggers?api-version=2016-08-01"

if [ $? -eq 0 ]; then
    echo "Function App Deployment completed successfully."
else
    echo "Function App Zip Deployment failed"
    exit 1
fi
