#!/bin/bash

#######################################################
# Creates and deploys a zip file for simulating parking data 
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################


set -o errexit
set -o pipefail
set -o nounset

pushd ./data/data-simulator

zip -q data-simulator.zip .env app.js package.json web.config
zip -q -r data-simulator.zip sensors/ helpers/ collections/

az webapp config appsettings set --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME" --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true
az webapp deploy --clean true --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME" --src-path ./data-simulator.zip --type zip --async true

# Restart the webapp to ensure the latest changes are applied
az webapp stop --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME"
az webapp start --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME"

rm data-simulator.zip

popd