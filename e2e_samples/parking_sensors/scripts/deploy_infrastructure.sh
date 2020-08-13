#!/bin/bash

# Access granted under MIT Open Source License: https://en.wikipedia.org/wiki/MIT_License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, # and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions 
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.

#######################################################
# Deploys all necessary azure resources and stores
# configuration information in an .ENV file
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# ENV_NAME
# RESOURCE_GROUP_NAME
# RESOURCE_GROUP_LOCATION
# AZURE_SUBSCRIPTION_ID
# AZURESQL_SERVER_PASSWORD


#####################
# DEPLOY ARM TEMPLATE

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID"
az account set --subscription $AZURE_SUBSCRIPTION_ID

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP_NAME"
az group create --name "$RESOURCE_GROUP_NAME" --location "$RESOURCE_GROUP_LOCATION" --tags Environment=$ENV_NAME

# By default, set all KeyVault permission to deployer
# Retrieve KeyVault User Id
kv_owner_object_id=$(az ad signed-in-user show --output json | jq -r '.objectId')

# Deploy arm template
echo "Deploying resources into $RESOURCE_GROUP_NAME"
arm_output=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "./infrastructure/azuredeploy.json" \
    --parameters @"./infrastructure/azuredeploy.parameters.${ENV_NAME}.json" \
    --parameters keyvault_owner_object_id=${kv_owner_object_id} deployment_id=${DEPLOYMENT_ID} sqlServerPassword=${AZURESQL_SERVER_PASSWORD} \
    --output json)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed." 
    exit 1
fi


#########################
# CREATE AND CONFIGURE SERVICE PRINCIPAL FOR ADLA GEN2

# Retrieve storage account name
export AZURE_STORAGE_ACCOUNT=$(echo $arm_output | jq -r '.properties.outputs.storage_account_name.value')

# Retrieve storage account (ADLS Gen2) key
export AZURE_STORAGE_KEY=$(az storage account keys list \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP_NAME \
    --output json |
    jq -r '.[0].value')

# Retrieve full storage account azure id
stor_id=$(az storage account show \
    --name "$AZURE_STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --output json |
    jq -r '.id')

# Add file system storage account
storage_file_system=datalake
echo "Creating ADLS Gen2 File system: $storage_file_system"
az storage container create --name $storage_file_system

echo "Creating folders within the file system."
# Create folders for databricks libs
az storage fs directory create -n '/sys/databricks/libs' -f $storage_file_system
# Create folders for SQL external tables
az storage fs directory create -n '/data/dw/fact_parking' -f $storage_file_system
az storage fs directory create -n '/data/dw/dim_st_marker' -f $storage_file_system
az storage fs directory create -n '/data/dw/dim_parking_bay' -f $storage_file_system
az storage fs directory create -n '/data/dw/dim_location' -f $storage_file_system

echo "Uploading seed data to data/seed"
az storage blob upload --container-name $storage_file_system\
    --file data/seed/dim_date.csv --name "data/seed/dim_date/dim_date.csv"
az storage blob upload --container-name $storage_file_system \
    --file data/seed/dim_time.csv --name "data/seed/dim_time/dim_time.csv"

# Create SP and grant correct rights to storage account
sp_stor_name=$(echo $arm_output | jq -r '.properties.outputs.service_principal_storage_name.value')
echo "Creating Service Principal (SP) for access to ADLA Gen2: '$sp_stor_name'"
sp_stor_out=$(az ad sp create-for-rbac \
    --role "Storage Blob Data Contributor" \
    --scopes "$stor_id" \
    --name $sp_stor_name \
    --output json)
export SP_STOR_ID=$(echo $sp_stor_out | jq -r '.appId')
export SP_STOR_PASS=$(echo $sp_stor_out | jq -r '.password')
export SP_STOR_TENANT=$(echo $sp_stor_out | jq -r '.tenant')


###################
# SQL

echo "Retrieving SQL Server information from the deployment."
# Retrieve SQL creds
export SQL_SERVER_NAME=$(echo $arm_output | jq -r '.properties.outputs.sql_server_name.value')
export SQL_SERVER_USERNAME=$(echo $arm_output | jq -r '.properties.outputs.sql_server_username.value')
export SQL_SERVER_PASSWORD=$(echo $arm_output | jq -r '.properties.outputs.sql_server_password.value')
export SQL_DW_DATABASE_NAME=$(echo $arm_output | jq -r '.properties.outputs.sql_dw_database_name.value')

# SQL Connection String
sql_dw_connstr_nocred=$(az sql db show-connection-string --client ado.net \
    --name $SQL_DW_DATABASE_NAME --server $SQL_SERVER_NAME --output json |
    jq -r .)
sql_dw_connstr_uname=${sql_dw_connstr_nocred/<username>/$SQL_SERVER_USERNAME}
sql_dw_connstr_uname_pass=${sql_dw_connstr_uname/<password>/$SQL_SERVER_PASSWORD}


####################
# APPLICATION INSIGHTS

echo "Retrieving ApplicationInsights information from the deployment."
appinsights_name=$(echo $arm_output | jq -r '.properties.outputs.appinsights_name.value')
export APPINSIGHTS_KEY=$(az monitor app-insights component show \
    --app "$appinsights_name" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --output json |
    jq -r '.instrumentationKey')


# ###########################
# # RETRIEVE DATABRICKS INFORMATION AND CONFIGURE WORKSPACE
# 
echo "Retrieving Databricks information from the deployment."
databricks_location=$(echo $arm_output | jq -r '.properties.outputs.databricks_location.value')
databricks_workspace_name=$(echo $arm_output | jq -r '.properties.outputs.databricks_workspace_name.value')
databricks_workspace_id=$(echo $arm_output | jq -r '.properties.outputs.databricks_workspace_id.value')
export DATABRICKS_HOST=https://${databricks_location}.azuredatabricks.net

# Retrieve databricks PAT token
echo "Generating a Databricks PAT token."
databricks_global_token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken) # Databricks app global id
azure_api_token=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)
api_response=$(curl -sf $DATABRICKS_HOST/api/2.0/token/create \
  -H "Authorization: Bearer $databricks_global_token" \
  -H "X-Databricks-Azure-SP-Management-Token:$azure_api_token" \
  -H "X-Databricks-Azure-Workspace-Resource-Id:$databricks_workspace_id" \
  -d '{ "comment": "For deployment" }')
databricks_token=$(echo $api_response | jq -r '.token_value')
export DATABRICKS_TOKEN=$databricks_token

echo "Waiting for Databricks workspace to be ready..."
sleep 3m # It takes a while for a databricks workspace to be ready for new clusters.

# Configure databricks
. ./scripts/configure_databricks.sh


####################
# DATA FACTORY

# Retrieve KeyVault details
echo "Retrieving KeyVault information from the deployment."
kv_name=$(echo $arm_output | jq -r '.properties.outputs.keyvault_name.value')
export KV_URL=https://$kv_name.vault.azure.net/

echo "Updating Data Factory LinkedService to point to newly deployed resources (KeyVault and DataLake)."
# Create a copy of the ADF dir into a .tmp/ folder.
adfTempDir=.tmp/adf
mkdir -p $adfTempDir && cp -a adf/ .tmp/
# Update LinkedServices to point to newly deployed Datalake and KeyVault
tmpfile=.tmpfile
adfLsDir=$adfTempDir/linkedService
jq --arg kvurl "$KV_URL" '.properties.typeProperties.baseUrl = $kvurl' $adfLsDir/Ls_KeyVault_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_KeyVault_01.json
jq --arg datalakeUrl "https://$AZURE_STORAGE_ACCOUNT.dfs.core.windows.net" '.properties.typeProperties.url = $datalakeUrl' $adfLsDir/Ls_AdlsGen2_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_AdlsGen2_01.json

# Deploy ADF artifacts
export DATAFACTORY_NAME=$(echo $arm_output | jq -r '.properties.outputs.datafactory_name.value')
export ADF_DIR=$adfTempDir
. ./scripts/deploy_adf_artifacts.sh

# SP for integration tests
sp_adf_name=$(echo $arm_output | jq -r '.properties.outputs.service_principal_datafactory_name.value')
sp_adf_out=$(az ad sp create-for-rbac \
    --role "Data Factory contributor" \
    --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.DataFactory/factories/$DATAFACTORY_NAME" \
    --name "$sp_adf_name" \
    --output json)
export SP_ADF_ID=$(echo $sp_adf_out | jq -r '.appId')
export SP_ADF_PASS=$(echo $sp_adf_out | jq -r '.password')
export SP_ADF_TENANT=$(echo $sp_adf_out | jq -r '.tenant')


####################
# SAVE RELEVANT SECRETS IN KEYVAULT

echo "Storing secrets in KeyVault."
az keyvault secret set --vault-name $kv_name --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID"
az keyvault secret set --vault-name $kv_name --name "kvUrl" --value "$KV_URL"
az keyvault secret set --vault-name $kv_name --name "sqlsrvrName" --value "$SQL_SERVER_NAME"
az keyvault secret set --vault-name $kv_name --name "sqlsrvUsername" --value "$SQL_SERVER_USERNAME"
az keyvault secret set --vault-name $kv_name --name "sqlsrvrPassword" --value "$SQL_SERVER_PASSWORD"
az keyvault secret set --vault-name $kv_name --name "sqldwDatabaseName" --value "$SQL_DW_DATABASE_NAME"
az keyvault secret set --vault-name $kv_name --name "sqldwConnectionString" --value "$sql_dw_connstr_uname_pass"
az keyvault secret set --vault-name $kv_name --name "datalakeAccountName" --value "$AZURE_STORAGE_ACCOUNT"
az keyvault secret set --vault-name $kv_name --name "datalakeKey" --value "$AZURE_STORAGE_KEY"
az keyvault secret set --vault-name $kv_name --name "spStorName" --value "$sp_stor_name"
az keyvault secret set --vault-name $kv_name --name "spStorId" --value "$SP_STOR_ID"
az keyvault secret set --vault-name $kv_name --name "spStorPass" --value "$SP_STOR_PASS"
az keyvault secret set --vault-name $kv_name --name "spStorTenantId" --value "$SP_STOR_TENANT"
az keyvault secret set --vault-name $kv_name --name "databricksDomain" --value "$DATABRICKS_HOST"
az keyvault secret set --vault-name $kv_name --name "databricksToken" --value "$DATABRICKS_TOKEN"
az keyvault secret set --vault-name $kv_name --name "applicationInsightsKey" --value "$APPINSIGHTS_KEY"
az keyvault secret set --vault-name $kv_name --name "adfName" --value "$DATAFACTORY_NAME"
az keyvault secret set --vault-name $kv_name --name "spAdfName" --value "$sp_adf_name"
az keyvault secret set --vault-name $kv_name --name "spAdfId" --value "$SP_ADF_ID"
az keyvault secret set --vault-name $kv_name --name "spAdfPass" --value "$SP_ADF_PASS"
az keyvault secret set --vault-name $kv_name --name "spAdfTenantId" --value "$SP_ADF_TENANT"

####################
# AZDO Azure Service Connection and Variables Groups
. ./scripts/deploy_azdo_service_connections_azure.sh
. ./scripts/deploy_azdo_variables.sh


####################
# BUILD ENV FILE FROM CONFIG INFORMATION

env_file=".env.${ENV_NAME}"
echo "Appending configuration to .env file."
cat << EOF >> $env_file

# ------ Configuration from deployment on ${TIMESTAMP} -----------
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME}
RESOURCE_GROUP_LOCATION=${RESOURCE_GROUP_LOCATION}
SQL_SERVER_NAME=${SQL_SERVER_NAME}
SQL_SERVER_USERNAME=${SQL_SERVER_USERNAME}
SQL_SERVER_PASSWORD=${SQL_SERVER_PASSWORD}
SQL_DW_DATABASE_NAME=${SQL_DW_DATABASE_NAME}
AZURE_STORAGE_ACCOUNT=${AZURE_STORAGE_ACCOUNT}
AZURE_STORAGE_KEY=${AZURE_STORAGE_KEY}
SP_STOR_NAME=${sp_stor_name}
SP_STOR_ID=${SP_STOR_ID}
SP_STOR_PASS=${SP_STOR_PASS}
SP_STOR_TENANT=${SP_STOR_TENANT}
DATABRICKS_HOST=${DATABRICKS_HOST}
DATABRICKS_TOKEN=${DATABRICKS_TOKEN}
DATAFACTORY_NAME=${DATAFACTORY_NAME}
APPINSIGHTS_KEY=${APPINSIGHTS_KEY}
KV_URL=${KV_URL}

EOF
echo "Completed deploying Azure resources $RESOURCE_GROUP_NAME ($ENV_NAME)"
