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
# AZDO_PROJECT
# AZDO_ORGANIZATION_URL
# AZURE_DEVOPS_EXT_PAT

. ./scripts/init_environment.sh

# add by Bo for test  
# step 1 TODO Add by Bo
# export ENV_NAME="botestadf"
# export RESOURCE_GROUP_NAME="botestadf"
# export AZURE_LOCATION="eastus"
# export AZURE_SUBSCRIPTION_ID=""
# export DEPLOYMENT_ID="2w4"

#step 2 variable for deploy_azdo_service_connections_azure.sh
# export AZURE_DEVOPS_ORG="bwa0800"
# export AZURE_DEVOPS_PROJECT="adf-test"
# #how to create/get AZURE_DEVOPS_EXT_PAT
# export AZURE_DEVOPS_EXT_PAT=""

# step 3 deploy_azdo_variables.sh
# None

#####################
# DEPLOY ARM TEMPLATE

# Create resource group
resource_group_name="adf-$DEPLOYMENT_ID-$ENV_NAME-rg"
echo "Creating resource group: $resource_group_name"
az group create --name "$resource_group_name" --location "$AZURE_LOCATION" --tags Environment=$ENV_NAME

# By default, set all KeyVault permission to deployer
# Retrieve KeyVault User Id
kv_owner_object_id=$(az ad signed-in-user show --output json | jq -r '.id')



# add by bo ===>  The default parameter can be used for this parameter and default value at ../infra/azuredeploy.json file
#  --parameters @"azuredeploy.parameters.${ENV_NAME}.json" \
# Deploy arm template
echo "Deploying resources into $resource_group_name"
arm_output=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "../infra/azuredeploy.json" \
    --parameters keyvault_owner_object_id=${kv_owner_object_id} deployment_id=${DEPLOYMENT_ID} \
    --output json)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed."
    exit 1
fi

#########################
# CONFIGURE DATA LAKE

# Retrieve storage account name
dl_storage_account=$(echo $arm_output | jq -r '.properties.outputs.datalake_storage_account_name.value')
export DL_STORAGE_ACCOUNT=$dl_storage_account

# Retrieve storage account (ADLS Gen2) key
dl_storage_key=$(az storage account keys list \
    --account-name $dl_storage_account \
    --resource-group $RESOURCE_GROUP_NAME \
    --output json |
    jq -r '.[0].value')
export DL_STORAGE_KEY=$dl_storage_key

# Retrieve full storage account azure id
dl_stor_id=$(az storage account show \
    --name "$dl_storage_account" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --output json |
    jq -r '.id')

# Add file system storage account
storage_file_system=datalake
echo "Creating ADLS Gen2 File system: $storage_file_system"
az storage container create --account-name $dl_storage_account --account-key $dl_storage_key --name $storage_file_system

echo "Creating folders within the file system."
declare -a zones=("/bronze" "/silver" "/gold")
for zone in "${zones[@]}"
do
    az storage fs directory create --account-name $dl_storage_account --account-key $dl_storage_key -n $zone -f $storage_file_system
done

az storage blob directory upload -c datalake --account-name $DL_STORAGE_ACCOUNT -s "cereals.csv" -d bronze --recursive
# Get Azure Data Factory managed service identity
export DATAFACTORY_NAME=$(echo $arm_output | jq -r '.properties.outputs.datafactory_name.value')
adf_msi=$(az resource show \
         --name $DATAFACTORY_NAME \
         --resource-group $RESOURCE_GROUP_NAME \
         --resource-type "Microsoft.DataFactory/factories" \
         --output json |
         jq -r '.identity.principalId')

# Grant storage rights to ADF MSI
az role assignment create --assignee-object-id $adf_msi --role "Storage Blob Data Owner" --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$dl_storage_account"


####################
# RETREIVE KEY VAULT DETAILS

# Retrieve KeyVault details
echo "Retrieving KeyVault information from the deployment."
kv_name=$(echo $arm_output | jq -r '.properties.outputs.keyvault_name.value')
export KV_URL=https://$kv_name.vault.azure.net/


####################
# Set up AZDO Azure Service Connection and Variables Groups
# AzDO Azure Service Connections
PROJECT=$PROJECT \
ENV_NAME=$ENV_NAME \
RESOURCE_GROUP_NAME=$resource_group_name \
AZDO_ORGANIZATION_URL=$AZDO_ORGANIZATION_URL \
AZURE_DEVOPS_EXT_PAT=$AZURE_DEVOPS_EXT_PAT \
    bash -c "./scripts/deploy_azdo_service_connections_azure.sh"

ENV_NAME=$ENV_NAME
AZURE_LOCATION=$AZURE_LOCATION
RESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME
DATAFACTORY_NAME=$DATAFACTORY_NAME
AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
DL_STORAGE_ACCOUNT=$DL_STORAGE_ACCOUNT
    bash -c "./scripts/deploy_azdo_variables.sh"


####################
# BUILD ENV FILE FROM CONFIG INFORMATION

env_file=".env.${ENV_NAME}"
echo "Appending configuration to .env file."
cat << EOF >> $env_file

RESOURCE_GROUP_NAME=${resource_group_name}
AZURE_LOCATION=${AZURE_LOCATION}
DL_STORAGE_ACCOUNT=${DL_STORAGE_ACCOUNT}
DL_STORAGE_KEY=${DL_STORAGE_KEY}
DATAFACTORY_NAME=${DATAFACTORY_NAME}
KV_URL=${KV_URL}

EOF

echo "Completed deploying Azure resources $resource_group_name ($ENV_NAME)"