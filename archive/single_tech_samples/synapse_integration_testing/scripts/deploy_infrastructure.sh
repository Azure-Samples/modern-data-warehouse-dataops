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
# ENV_NAME
# AZURE_LOCATION
# AZURE_SUBSCRIPTION_ID
# SYNAPSE_SQL_PASSWORD


#####################
# DEPLOY ARM TEMPLATE

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Create resource group
resource_group_name="$PROJECT-$DEPLOYMENT_ID-$ENV_NAME-rg"
echo "Creating resource group: $resource_group_name"
az group create --name "$resource_group_name" --location "$AZURE_LOCATION" --tags Environment="$ENV_NAME"

# By default, set all KeyVault permission to deployer
# Retrieve KeyVault User Id
kv_owner_object_id=$(az ad signed-in-user show --query id --output tsv)

# Get endpoints for Azure resources
azcloud=$(az cloud show --output json)
storageEndpointSuffix=$(echo "$azcloud" | jq -r '.suffixes.storageEndpoint')
keyVaultEndpointSuffix=$(echo "$azcloud" | jq -r '.suffixes.keyvaultDns')
synapseEndpointSuffix=$(echo "$azcloud" | jq -r '.suffixes.synapseAnalyticsEndpoint')
adlsStorageEndpointSuffix=".dfs.${storageEndpointSuffix}"

# Validate arm template

echo "Validating deployment"
arm_output=$(az deployment group validate \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters @"./infrastructure/main.parameters.${ENV_NAME}.json" \
    --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" deployment_id="${DEPLOYMENT_ID}" synapse_sqlpool_admin_password="${SYNAPSE_SQL_PASSWORD}" \
    --output json)

# Deploy arm template
echo "Deploying resources into $resource_group_name"
arm_output=$(az deployment group create \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters @"./infrastructure/main.parameters.${ENV_NAME}.json" \
    --parameters project="${PROJECT}" deployment_id="${DEPLOYMENT_ID}" keyvault_owner_object_id="${kv_owner_object_id}" synapse_sqlpool_admin_password="${SYNAPSE_SQL_PASSWORD}" \
    --output json)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed."
    exit 1
fi


########################
# RETRIEVE KEYVAULT INFORMATION

echo "Retrieving KeyVault information from the deployment."

kv_name=$(echo "$arm_output" | jq -r '.properties.outputs.keyvault_name.value')
kv_dns_name="https://${kv_name}${keyVaultEndpointSuffix}/"


# Store in KeyVault
az keyvault secret set --vault-name "$kv_name" --name "kvUrl" --value "$kv_dns_name"
az keyvault secret set --vault-name "$kv_name" --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID"


#########################
# CREATE AND CONFIGURE SERVICE PRINCIPAL FOR ADLS GEN2

# Retrive account and key
azure_storage_account=$(echo "$arm_output" | jq -r '.properties.outputs.storage_account_name.value')
azure_storage_key=$(az storage account keys list \
    --account-name "$azure_storage_account" \
    --resource-group "$resource_group_name" \
    --query [0].value --output tsv)

# Add file system storage account
storage_file_system=datalake
echo "Creating ADLS Gen2 File system: $storage_file_system"
az storage container create --name $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key"

processed_file_system=saveddata
az storage container create --name $processed_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key"

# Set Keyvault secrets
datalakeurl="https://${azure_storage_account}.dfs.${storageEndpointSuffix}"

az keyvault secret set --vault-name "$kv_name" --name "datalakeAccountName" --value "$azure_storage_account"
az keyvault secret set --vault-name "$kv_name" --name "datalakeKey" --value "$azure_storage_key"
az keyvault secret set --vault-name "$kv_name" --name "datalakeurl" --value "$datalakeurl"


####################
# SYNAPSE ANALYTICS

echo "Retrieving Synapse Analytics information from the deployment."
synapseworkspace_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapseworskspace_name.value')
synapse_workspace=$(az synapse workspace show \
    --name "$synapseworkspace_name" \
    --resource-group "$resource_group_name" \
    --output json)
synapse_dev_endpoint=$(echo $synapse_workspace | jq -r '.connectivityEndpoints | .dev')
sqlPoolServer=$(echo "$synapse_workspace" | jq -r '.connectivityEndpoints.sql')

synapse_sparkpool_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapse_output_spark_pool_name.value')
synapse_sqlpool_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapse_sql_pool_output.value.synapse_pool_name')

# The server name of connection string will be the same as Synapse workspace name
synapse_sqlpool_server=$(echo "$arm_output" | jq -r '.properties.outputs.synapseworskspace_name.value')
synapse_sqlpool_admin_username=$(echo "$arm_output" | jq -r '.properties.outputs.synapse_sql_pool_output.value.username')
# the database name of dedicated sql pool will be the same with dedicated sql pool by default
synapse_dedicated_sqlpool_db_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapse_sql_pool_output.value.synapse_pool_name')

# Store in Keyvault
az keyvault secret set --vault-name "$kv_name" --name "synapseWorkspaceName" --value "$synapseworkspace_name"
az keyvault secret set --vault-name "$kv_name" --name "synapseDevEndpoint" --value "$synapse_dev_endpoint"
az keyvault secret set --vault-name "$kv_name" --name "synapseSparkPoolName" --value "$synapse_sparkpool_name"
az keyvault secret set --vault-name "$kv_name" --name "synapseSqlPoolServerName" --value "$synapse_sqlpool_server"
az keyvault secret set --vault-name "$kv_name" --name "synapseSQLPoolAdminUsername" --value "$synapse_sqlpool_admin_username"
az keyvault secret set --vault-name "$kv_name" --name "synapseSQLPoolAdminPassword" --value "$SYNAPSE_SQL_PASSWORD"
az keyvault secret set --vault-name "$kv_name" --name "synapseDedicatedSQLPoolDBName" --value "$synapse_dedicated_sqlpool_db_name"

# Create variables
PIPELINE_NAME="P_$PROJECT-$DEPLOYMENT_ID-$ENV_NAME"
TRIGGER_NAME="T_Stor_$PROJECT-$DEPLOYMENT_ID-$ENV_NAME"

# Deploy Synapse artifacts
AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
RESOURCE_GROUP_NAME=$resource_group_name \
SYNAPSE_WORKSPACE_NAME=$synapseworkspace_name \
SYNAPSE_DEV_ENDPOINT=$synapse_dev_endpoint \
BIG_DATAPOOL_NAME=$synapse_sparkpool_name \
SQL_POOL_NAME=$synapse_sqlpool_name \
KEYVAULT_NAME=$kv_name \
KEYVAULT_ENDPOINT=$keyVaultEndpointSuffix \
AZURE_STORAGE_ACCOUNT=$azure_storage_account \
PIPELINE_NAME=$PIPELINE_NAME \
TRIGGER_NAME=$TRIGGER_NAME \
    bash -c "./scripts/deploy_synapse_artifacts.sh"


# SERVICE PRINCIPAL IN SYNAPSE INTEGRATION TESTS
# Synapse SP for integration tests
 sp_synapse_name="${PROJECT}-syn-${ENV_NAME}-${DEPLOYMENT_ID}-sp"
 sp_synapse_out=$(az ad sp create-for-rbac \
     --role Contributor \
     --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$resource_group_name/providers/Microsoft.Synapse/workspaces/$synapseworkspace_name" \
     --name "$sp_synapse_name" \
     --output json)
 sp_synapse_id=$(echo "$sp_synapse_out" | jq -r '.appId')
 sp_synapse_pass=$(echo "$sp_synapse_out" | jq -r '.password')
 sp_synapse_tenant=$(echo "$sp_synapse_out" | jq -r '.tenant')

# Save Synapse SP credentials in Keyvault
 az keyvault secret set --vault-name "$kv_name" --name "spSynapseName" --value "$sp_synapse_name"
 az keyvault secret set --vault-name "$kv_name" --name "spSynapseId" --value "$sp_synapse_id"
 az keyvault secret set --vault-name "$kv_name" --name "spSynapsePass" --value "$sp_synapse_pass"
 az keyvault secret set --vault-name "$kv_name" --name "spSynapseTenantId" --value "$sp_synapse_tenant"

# Grant Synapse Administrator to this SP so that it can trigger Synapse pipelines
wait_service_principal_creation "$sp_synapse_id"
sp_synapse_object_id=$(az ad sp show --id "$sp_synapse_id" --query "id" -o tsv)
assign_synapse_role_if_not_exists "$synapseworkspace_name" "Synapse Administrator" "$sp_synapse_object_id"
assign_synapse_role_if_not_exists "$synapseworkspace_name" "Synapse SQL Administrator" "$sp_synapse_object_id"
assign_storage_role "$azure_storage_account" "$resource_group_name" "Storage Blob Data Contributor" "$sp_synapse_object_id"
assign_storage_role "$azure_storage_account" "$resource_group_name" "Storage Blob Data Contributor" "$sp_synapse_object_id"

####################
# BUILD ENV FILE FROM CONFIG INFORMATION

env_file=".env.${ENV_NAME}"
echo "Appending configuration to .env file."
cat << EOF >> "$env_file"


# ------ Configuration from deployment on ${TIMESTAMP} -----------
AZ_SERVICE_PRINCIPAL_CLIENT_ID=${sp_synapse_id}
AZ_SERVICE_PRINCIPAL_SECRET=${sp_synapse_pass}
AZ_SERVICE_PRINCIPAL_TENANT_ID=${sp_synapse_tenant}
AZ_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZ_RESOURCE_GROUP_NAME=${resource_group_name}
AZ_SYNAPSE_NAME=${synapseworkspace_name}
AZ_SYNAPSE_ENDPOINT_SUFFIX=${synapseEndpointSuffix}
AZ_SYNAPSE_DEDICATED_SQLPOOL_SERVER=${sqlPoolServer}
AZ_SYNAPSE_SQLPOOL_ADMIN_USERNAME=${synapse_sqlpool_admin_username}
AZ_SYNAPSE_SQLPOOL_ADMIN_PASSWORD=${SYNAPSE_SQL_PASSWORD}
AZ_SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME=${synapse_dedicated_sqlpool_db_name}
PIPELINE_NAME=$PIPELINE_NAME
TRIGGER_NAME=$TRIGGER_NAME
ADLS_ACCOUNT_NAME=${azure_storage_account}
ADLS_ACCOUNT_ENDPOINT_SUFFIX=${adlsStorageEndpointSuffix}
ADLS_DESTINATION_CONTAINER=${storage_file_system}
ADLS_PROCESSED_CONTAINER=${processed_file_system}

EOF
echo "Completed deploying Azure resources $resource_group_name ($ENV_NAME)"
