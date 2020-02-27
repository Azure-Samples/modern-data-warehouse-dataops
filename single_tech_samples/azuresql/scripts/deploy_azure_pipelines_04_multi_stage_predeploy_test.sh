#!/bin/bash

###############
# Deploy Pipelines: multi-stage predeploy

echo "Deploying resources for multi-stage with predeployment test pipeline into $RESOURCE_GROUP_NAME"

# Deploy Keyvault
keyvault_name="mdwdo-azsql-${DEPLOYMENT_ID}-kv"
az keyvault create -n $keyvault_name -g $RESOURCE_GROUP_NAME -l $RESOURCE_GROUP_LOCATION --tags "source=mdw-dataops" "deployment=$DEPLOYMENT_ID"
keyvault_secret_name="AZURESQL-SERVER-KEYVAULT-PASSWORD"

az keyvault secret set --vault-name $keyvault_name --name $keyvault_secret_name --value $AZURESQL_SERVER_PASSWORD --tags "source=mdw-dataops" "deployment=$DEPLOYMENT_ID"
az keyvault set-policy --name $keyvault_name --spn $SERVICE_PRINCIPAL_ID --secret-permissions get list

# Deploy AzureSQL
sqlsrvr_name=mdwdo-azsql-${DEPLOYMENT_ID}-sqlsrvr04

echo "Deploying Azure SQL server $sqlsrvr_name"

arm_output=$(az group deployment create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "./infrastructure/azuredeploy.json" \
    --parameters AZURESQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD} azuresql_srvr_name=${sqlsrvr_name} azuresql_srvr_display_name="SQL Server - Multi-Stage Pipeline with pre-deployment test" deployment_id=${DEPLOYMENT_ID} \
    --output json)

# Create pipeline
pipeline_name=mdwdo-azsql-${DEPLOYMENT_ID}-azuresql-04-multi-stage-w-predeploy-test
echo "Creating Pipeline: $pipeline_name in Azure DevOps"
pipeline_id=$(az pipelines create \
    --name "$pipeline_name" \
    --description 'This pipeline is an advanced three stage pipeline which builds the DACPAC, deploys to a test database restored from production, and deploys to a target AzureSQLDB instance.' \
    --repository "$GITHUB_REPO_URL" \
    --branch "$BRANCH_NAME" \
    --yaml-path 'single_tech_samples/azuresql/pipelines/azure-pipelines-04-multi-stage-predeploy-test.yml' \
    --service-connection "$GITHUB_SERVICE_CONNECTION_ID" \
    --skip-first-run true \
    --output json | jq -r '.id')

# Create Variables
az pipelines variable create \
    --name RESOURCE_GROUP_NAME \
    --pipeline-id $pipeline_id \
    --value "$RESOURCE_GROUP_NAME"

az pipelines variable create \
    --name AZURESQL_SERVER_NAME \
    --pipeline-id $pipeline_id \
    --value "$sqlsrvr_name"

azuresql_db_name=$(echo $arm_output | jq -r '.properties.outputs.azuresql_db_name.value')
az pipelines variable create \
    --name AZURESQL_DB_NAME \
    --pipeline-id $pipeline_id \
    --value $azuresql_db_name

azuresql_srvr_admin=$(echo $arm_output | jq -r '.properties.outputs.azuresql_srvr_admin.value')
az pipelines variable create \
    --name AZURESQL_SERVER_USERNAME \
    --pipeline-id $pipeline_id \
    --value $azuresql_srvr_admin

az pipelines variable create \
    --name AZURE_KEYVAULT_NAME \
    --pipeline-id $pipeline_id \
    --value "$keyvault_name"

az pipelines run --name $pipeline_name