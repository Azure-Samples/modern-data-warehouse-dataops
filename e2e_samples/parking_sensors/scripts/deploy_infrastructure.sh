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
set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# ENV_NAME
# RESOURCE_GROUP_NAME
# RESOURCE_GROUP_LOCATION
# AZURE_SUBSCRIPTION_ID


#####################
# DEPLOY ARM TEMPLATE

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID"
az account set --subscription $AZURE_SUBSCRIPTION_ID

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP_NAME"
az group create --name "$RESOURCE_GROUP_NAME" --location "$RESOURCE_GROUP_LOCATION"

# By default, set all KeyVault permission to deployer
# Retrieve KeyVault User Id
kv_owner_object_id=$(az ad signed-in-user show --output json | jq -r '.objectId')

# Deploy arm template
echo "Deploying resources into $RESOURCE_GROUP_NAME"
arm_output=$(az group deployment create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "./infrastructure/azuredeploy.json" \
    --parameters @"./infrastructure/azuredeploy.parameters.${ENV_NAME}.json" \
    --parameters keyvault_owner_object_id=${kv_owner_object_id} deployment_id=${DEPLOYMENT_ID} \
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


# ###########################
# # RETRIEVE DATABRICKS INFORMATION AND CONFIGURE WORKSPACE
# 
databricks_location=$(echo $arm_output | jq -r '.properties.outputs.databricks_location.value')
databricks_workspace_name=$(echo $arm_output | jq -r '.properties.outputs.databricks_workspace_name.value')
databricks_workspace_id=$(echo $arm_output | jq -r '.properties.outputs.databricks_workspace_id.value')
export DATABRICKS_HOST=https://${databricks_location}.azuredatabricks.net

# Retrieve databricks PAT token
databricks_global_token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken) # Databricks app global id
azure_api_token=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)
api_response=$(curl -sf $DATABRICKS_HOST/api/2.0/token/create \
  -H "Authorization: Bearer $databricks_global_token" \
  -H "X-Databricks-Azure-SP-Management-Token:$azure_api_token" \
  -H "X-Databricks-Azure-Workspace-Resource-Id:$databricks_workspace_id" \
  -d '{ "comment": "For deployment" }')
databricks_token=$(echo $api_response | jq -r '.token_value')
export DATABRICKS_TOKEN=$databricks_token

# Configure databricks
sleep 5m # It takes a while for a databricks workspace to be ready for new clusters.
. ./scripts/configure_databricks.sh


####################
# SAVE RELEVANT SECRETS IN KEYVAULT

# Retrieve KeyVault details
kv_name=$(echo $arm_output | jq -r '.properties.outputs.keyvault_name.value')

az keyvault secret set --vault-name $kv_name --name "storageAccount" --value $AZURE_STORAGE_ACCOUNT
az keyvault secret set --vault-name $kv_name --name "storageKey" --value $AZURE_STORAGE_KEY
az keyvault secret set --vault-name $kv_name --name "spStorName" --value $sp_stor_name
az keyvault secret set --vault-name $kv_name --name "spStorId" --value $SP_STOR_ID
az keyvault secret set --vault-name $kv_name --name "spStorPass" --value $SP_STOR_PASS
az keyvault secret set --vault-name $kv_name --name "spStorTenantId" --value $SP_STOR_TENANT
az keyvault secret set --vault-name $kv_name --name "dbricksDomain" --value $DATABRICKS_HOST
az keyvault secret set --vault-name $kv_name --name "dbricksToken" --value $DATABRICKS_TOKEN


####################
# BUILD ENV FILE FROM CONFIG INFORMATION

env_file="../.env.${ENV_NAME}"
echo "Appending configuration to .env file."
cat << EOF >> $env_file

# ------ Configuration from deployment on ${TIMESTAMP} -----------
RESOURCE_GROUP=${RESOURCE_GROUP_NAME}
STORAGE_ACCOUNT=${AZURE_STORAGE_ACCOUNT}
STORAGE_KEY=${AZURE_STORAGE_KEY}
SP_STOR_NAME=${sp_stor_name}
SP_STOR_ID=${SP_STOR_ID}
SP_STOR_PASS=${SP_STOR_PASS}
SP_STOR_TENANT=${SP_STOR_TENANT}
KV_NAME=${kv_name}
DATABRICKS_HOST=${DATABRICKS_HOST}
DATABRICKS_TOKEN=${DATABRICKS_TOKEN}

EOF
echo "Completed deploying Azure resources $RESOURCE_GROUP_NAME ($ENV_NAME)"
