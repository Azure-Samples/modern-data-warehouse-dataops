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

. ./scripts/common.sh

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# DEPLOYMENT_ID
# AZURE_LOCATION
# AZURE_SUBSCRIPTION_ID


#####################
# DEPLOY ARM TEMPLATE

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Create resource group
resource_group_name="$PROJECT-$DEPLOYMENT_ID-rg"
echo "Creating resource group: $resource_group_name"
az group create --name "$resource_group_name" --location "$AZURE_LOCATION"

# By default retrieve signed-in-user
# The signed-in user will also receive all KeyVault persmissions
owner_object_id=$(az ad signed-in-user show --output json | jq -r '.id')

# Validate arm template
echo "Validating deployment"
arm_output=$(az deployment group validate \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters project="${PROJECT}" deployment_id="${DEPLOYMENT_ID}" keyvault_owner_object_id="${owner_object_id}"  \
    --output json)

# Deploy arm template
echo "Deploying resources into $resource_group_name"
arm_output=$(az deployment group create \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters project="${PROJECT}" deployment_id="${DEPLOYMENT_ID}" keyvault_owner_object_id="${owner_object_id}" \
    --output json)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed."
    exit 1
fi


##########################################
# Upload Data Lake Configuration File

# Retrive account and key
azure_storage_account=$(echo "$arm_output" | jq -r '.properties.outputs.storage_account_name.value')
azure_storage_key=$(az storage account keys list \
    --account-name "$azure_storage_account" \
    --resource-group "$resource_group_name" \
    --output json | jq -r '.[0].value')

echo "Generating Config file using the template"
cat ./scripts/config/datalake_config_template.json|sed -e "s/<project_name>/${PROJECT}/g" -e "s/<deployment_id>/${DEPLOYMENT_ID}/g" > ./scripts/config/datalake_config.json

echo "Uploading Config file within the file system."
az storage blob upload --container-name 'config' --account-name "$azure_storage_account" --account-key "$azure_storage_key" \
    --file scripts/config/datalake_config.json --name "datalake_config.json" --overwrite -o none
kv_name=$(echo "$arm_output" | jq -r '.properties.outputs.keyvault_name.value')
az keyvault secret set --vault-name "$kv_name" --name "datalakeKey" --value "$azure_storage_key" -o none


####################
# SYNAPSE ANALYTICS

echo "Retrieving Synapse Analytics information from the deployment."
synapseworkspace_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapseworskspace_name.value')
echo "$synapseworkspace_name"
synapse_serverless_endpoint=$(az synapse workspace show \
    --name "$synapseworkspace_name" \
    --resource-group "$resource_group_name" \
    --output json |
    jq -r '.connectivityEndpoints | .sqlOnDemand')

synapse_sparkpool_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapse_output_spark_pool_name.value')

sleep 20

# Grant Synapse Administrator to the deployment owner
assign_synapse_role_if_not_exists "$synapseworkspace_name" "Synapse Administrator" "$owner_object_id"
assign_synapse_role_if_not_exists "$synapseworkspace_name" "Synapse Contributor" "$synapseworkspace_name"

####################
# CLS

#######################
# RBAC - Control Plane
# Create a AAD Group, if you have permissions to do it (otherwise you will need to request to the AAD admin and comment this line)
echo "Creating AAD Group:AADGR${PROJECT}${DEPLOYMENT_ID}"
aad_group_name="AADGR${PROJECT}${DEPLOYMENT_ID}"
aad_group_output=$(az ad group create --display-name "${aad_group_name}" --mail-nickname "${aad_group_name}" --output json)
aad_group_id=$(echo $aad_group_output | jq -r '.id')

echo "Adding the AAD Group id to the KeyVault"
az keyvault secret set --vault-name "$kv_name" --name "$aad_group_name" --value "$aad_group_id" -o none

##########################
# Deploy Synapse artifacts
#AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
PROJECT_NAME=$PROJECT \
DEPLOYMENT_ID=$DEPLOYMENT_ID \
RESOURCE_GROUP_NAME=$resource_group_name \
SYNAPSE_WORKSPACE_NAME=$synapseworkspace_name \
BIG_DATAPOOL_NAME=$synapse_sparkpool_name \
KEYVAULT_NAME=$kv_name \
    bash -c "./scripts/deploy_synapse_artifacts.sh"

####################
# CLS
# Get AAD Group ObjectID
aadGroupObjectId=$(az ad group list --filter "(displayName eq 'AADGR${PROJECT}${DEPLOYMENT_ID}')" --query "[].id" --output tsv)
echo "Get AAD Group id: ${aadGroupObjectId}"
until [ -n "${aadGroupObjectId}" ]
    do
        echo "waiting for the aad group to be created..."
        sleep 10
    done

#################
# RBAC - Synapse 
# Allow Synapse Reader access to the AADGroup
assign_synapse_role_if_not_exists "$synapseworkspace_name" "Synapse User" "$aadGroupObjectId"

# Add the owner of the deployment to the AAD Group, if you have permissions to do it (otherwise you will need to request to the AAD admin and comment this line)
#if [[ $(az ad group member check --group "AADGR${PROJECT}${DEPLOYMENT_ID}" --member-id ${owner_object_id}) == false ]]; then
echo "Adding members to AAD Group:AADGR${PROJECT}${DEPLOYMENT_ID}"
az ad group member add --group "AADGR${PROJECT}${DEPLOYMENT_ID}" --member-id $owner_object_id
#fi

# Allow Contributor to the AAD Group on Synapse workspace
az role assignment create --role "Contributor" --assignee-object-id "${aadGroupObjectId}" --assignee-principal-type "Group" --scope "/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${resource_group_name}/providers/Microsoft.Synapse/workspaces/${synapseworkspace_name}"

# Allow Contributor to the AAD Group on Synapse workspace
echo "Giving ACL permission on the datalake container for the AAD Group"
az storage fs access set --acl "group:${aadGroupObjectId}:rwx" -p "/" -f "datalake" --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none
