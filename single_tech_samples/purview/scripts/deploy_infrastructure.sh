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

# Register a Purview provider to the subscription
az provider register --namespace 'Microsoft.Purview'

# Deploy arm template
echo "Deploying resources into $RESOURCE_GROUP_NAME"
arm_output=$(az deployment group create \
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
declare -a zones=("/dropzone" "/bronze" "/silver" "/gold")
for zone in "${zones[@]}"
do
    az storage fs directory create --account-name $dl_storage_account --account-key $dl_storage_key -n $zone -f $storage_file_system
done

echo "Uploading sample data"
az storage blob upload --account-name $dl_storage_account --account-key $dl_storage_key --container-name $storage_file_system --file "data/Customers.csv" --name "Customers.csv"

# Get Azure Data Factory managed service identity
export DATAFACTORY_NAME=$(echo $arm_output | jq -r '.properties.outputs.datafactory_name.value')
adf_msi=$(az resource show \
         --name $DATAFACTORY_NAME \
         --resource-group $RESOURCE_GROUP_NAME \
         --resource-type "Microsoft.DataFactory/factories" | 
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
# SAVE RELEVANT SECRETS IN KEYVAULT

echo "Storing secrets in KeyVault."
az keyvault secret set --vault-name $kv_name --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID"
az keyvault secret set --vault-name $kv_name --name "kvUrl" --value "$KV_URL"
az keyvault secret set --vault-name $kv_name --name "datalakeAccountName" --value "$dl_storage_account"
az keyvault secret set --vault-name $kv_name --name "datalakeKey" --value "$dl_storage_key"

####################
# DATA FACTORY

echo "Updating Data Factory LinkedService in Dev to point to newly deployed resources (KeyVault and DataLake)."
# Update ADF LinkedServices to point to newly deployed Datalake URL, DataSource URL and KeyVault URL - only for Dev; Stg and Prod go through CI/CD Deployment
if [ $ENV_NAME = dev ]; then
    tmpfile=.tmpfile
    adfLsDir=./adf/linkedService
    jq --arg kvurl "$KV_URL" '.properties.typeProperties.baseUrl = $kvurl' $adfLsDir/KeyVault.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/KeyVault.json
    jq --arg datalakeUrl "https://$dl_storage_account.dfs.core.windows.net" '.properties.typeProperties.url = $datalakeUrl' $adfLsDir/DataLakeStorage.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/DataLakeStorage.json
    
    # Commit files back to branch so they are pulled from dev ADF
    git add $adfLsDir/DataLakeStorage.json
    git add $adfLsDir/KeyVault.json
    git commit -m "Updated Linked Services"
    git push origin
fi

#########################
# CONFIGURE PURVIEW

purview_account_name=$(echo $arm_output | jq -r '.properties.outputs.purview_name.value')
export PURVIEW_ACCOUNT_NAME=$purview_account_name

. ./scripts/deploy_purview_spn.sh

. ./scripts/deploy_purview_linkedservices.sh


####################
# BUILD ENV FILE FROM CONFIG INFORMATION

env_file=".env.${ENV_NAME}"
echo "Appending configuration to .env file."
cat << EOF >> $env_file

# ------ Configuration from deployment on ${TIMESTAMP} -----------
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME}
RESOURCE_GROUP_LOCATION=${RESOURCE_GROUP_LOCATION}
DL_STORAGE_ACCOUNT=${DL_STORAGE_ACCOUNT}
DL_STORAGE_KEY=${DL_STORAGE_KEY}
DATAFACTORY_NAME=${DATAFACTORY_NAME}
KV_URL=${KV_URL}
PURVIEW_ACCOUNT_NAME=${PURVIEW_ACCOUNT_NAME}
PURVIEW_SPN_APP_KEY=${PURVIEW_SPN_APP_KEY}
PURVIEW_SPN_APP_ID=${PURVIEW_SPN_APP_ID}

EOF

echo "Completed deploying Azure resources $RESOURCE_GROUP_NAME ($ENV_NAME)"
