#!/bin/bash
random_str() {
    local length=$1
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1 | tr '[:upper:]' '[:lower:]'
    return 0
}

location=$1
deploymentId=$(random_str 5)


########################
# DEPLOY REST API WEBAPP TO APPSERVICE
RESOURCE_GROUP_NAME="rg-data-simulator-${deploymentId}"
echo $RESOURCE_GROUP_NAME
APP_NAME="data-simulator-api-${deploymentId}"
echo "Deploying REST API to AppService: $APP_NAME"

az group create --name "$RESOURCE_GROUP_NAME" --location "$location" --output json

arm_output=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "./appservice.bicep" \
    --parameters project="data-simulator" deployment_id="${deploymentId}" location="${location}" \
    --output json)

pushd ../application/

echo "Deploying data-simulator to AppService: "

zip -q data-simulator.zip app.js
zip -q data-simulator.zip .env
zip -q data-simulator.zip package.json
zip -q data-simulator.zip web.config
zip -q -r data-simulator.zip sensors/
zip -q -r data-simulator.zip helpers/
zip -q -r data-simulator.zip collections/

az webapp config appsettings set --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME" --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true
az webapp deploy --clean --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME" --src-path ./data-simulator.zip --type zip --async true


rm data-simulator.zip

popd

echo "Deploy to https://$APP_NAME.azurewebsites.net complete."
