#!/bin/bash

pushd ./data/data-simulator

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