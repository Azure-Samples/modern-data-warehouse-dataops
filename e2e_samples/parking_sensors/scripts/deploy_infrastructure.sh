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
##set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# DEPLOYMENT_ID
# ENV_NAME
# AZURE_LOCATION
# AZURE_SUBSCRIPTION_ID
# AZURESQL_SERVER_PASSWORD


#####################
### DEPLOY ARM TEMPLATE
#####################

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Create resource group
resource_group_name="$PROJECT-$DEPLOYMENT_ID-$ENV_NAME-rg"
echo "Creating resource group: $resource_group_name"
az group create --name "$resource_group_name" --location "$AZURE_LOCATION" --tags Environment="$ENV_NAME"

# By default, set all KeyVault permission to deployer
# Retrieve KeyVault User Id
kv_owner_object_id=$(az ad signed-in-user show --output json | jq -r '.id')
kv_owner_name=$(az ad user show --id "$kv_owner_object_id" --output json | jq -r '.userPrincipalName')

# Validate arm template
echo "Validating deployment"
arm_output=$(az deployment group validate \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters @"./infrastructure/main.parameters.${ENV_NAME}.json" \
    --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" deployment_id="${DEPLOYMENT_ID}" \
    --parameters sql_server_password="${AZURESQL_SERVER_PASSWORD}" entra_admin_login="${kv_owner_name}" \
    --parameters enable_keyvault_soft_delete="${ENABLE_KEYVAULT_SOFT_DELETE}" enable_keyvault_purge_protection="${ENABLE_KEYVAULT_PURGE_PROTECTION}"\
    --output json)

# Deploy arm template
echo "Deploying resources into $resource_group_name"
arm_output=$(az deployment group create \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters @"./infrastructure/main.parameters.${ENV_NAME}.json" \
    --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" deployment_id="${DEPLOYMENT_ID}" \
    --parameters sql_server_password="${AZURESQL_SERVER_PASSWORD}" entra_admin_login="${kv_owner_name}" \
    --parameters enable_keyvault_soft_delete="${ENABLE_KEYVAULT_SOFT_DELETE}" enable_keyvault_purge_protection="${ENABLE_KEYVAULT_PURGE_PROTECTION}"\
    --output json)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed."
    exit 1
fi


########################
# RETRIEVE KEYVAULT INFORMATION

echo "Retrieving KeyVault information from the deployment."

kv_name=$(echo "$arm_output" | jq -r '.properties.outputs.keyvault_name.value')
kv_dns_name=https://${kv_name}.vault.azure.net/

# Store in KeyVault
az keyvault secret set --vault-name "$kv_name" --name "kvUrl" --value "$kv_dns_name"
az keyvault secret set --vault-name "$kv_name" --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID"


#########################
# CREATE AND CONFIGURE SERVICE PRINCIPAL FOR ADLA GEN2

# Retrive account and key
azure_storage_account=$(echo "$arm_output" | jq -r '.properties.outputs.storage_account_name.value')
azure_storage_key=$(az storage account keys list \
    --account-name "$azure_storage_account" \
    --resource-group "$resource_group_name" \
    --output json |
    jq -r '.[0].value')

# Add file system storage account
storage_file_system=datalake
echo "Creating ADLS Gen2 File system: $storage_file_system"
az storage container create --name $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key"

echo "Creating folders within the file system."
# Create folders for databricks libs
az storage fs directory create -n '/sys/databricks/libs' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key"
# Create folders for SQL external tables
az storage fs directory create -n '/data/dw/fact_parking' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key"
az storage fs directory create -n '/data/dw/dim_st_marker' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key"
az storage fs directory create -n '/data/dw/dim_parking_bay' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key"
az storage fs directory create -n '/data/dw/dim_location' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key"

echo "Uploading seed data to data/seed"
az storage blob upload --container-name $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" \
    --file data/seed/dim_date.csv --name "data/seed/dim_date/dim_date.csv" --overwrite
az storage blob upload --container-name $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" \
    --file data/seed/dim_time.csv --name "data/seed/dim_time/dim_time.csv" --overwrite

# Set Keyvault secrets
az keyvault secret set --vault-name "$kv_name" --name "datalakeAccountName" --value "$azure_storage_account"
az keyvault secret set --vault-name "$kv_name" --name "datalakeKey" --value "$azure_storage_key"
az keyvault secret set --vault-name "$kv_name" --name "datalakeurl" --value "https://$azure_storage_account.dfs.core.windows.net"

###################
# SQL

echo "Retrieving SQL Server information from the deployment."
# Retrieve SQL creds
sql_server_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapse_sql_pool_output.value.name')
sql_server_username=$(echo "$arm_output" | jq -r '.properties.outputs.synapse_sql_pool_output.value.username')
sql_dw_database_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapse_sql_pool_output.value.synapse_pool_name')

# SQL Connection String
sql_dw_connstr_nocred=$(az sql db show-connection-string --client ado.net \
    --name "$sql_dw_database_name" --server "$sql_server_name" --output json |
    jq -r .)
sql_dw_connstr_uname=${sql_dw_connstr_nocred/<username>/$sql_server_username}
sql_dw_connstr_uname_pass=${sql_dw_connstr_uname/<password>/$AZURESQL_SERVER_PASSWORD}

# Store in Keyvault
az keyvault secret set --vault-name "$kv_name" --name "sqlsrvrName" --value "$sql_server_name"
az keyvault secret set --vault-name "$kv_name" --name "sqlsrvUsername" --value "$sql_server_username"
az keyvault secret set --vault-name "$kv_name" --name "sqlsrvrPassword" --value "$AZURESQL_SERVER_PASSWORD"
az keyvault secret set --vault-name "$kv_name" --name "sqldwDatabaseName" --value "$sql_dw_database_name"
az keyvault secret set --vault-name "$kv_name" --name "sqldwConnectionString" --value "$sql_dw_connstr_uname_pass"


####################
# APPLICATION INSIGHTS

echo "Retrieving ApplicationInsights information from the deployment."
appinsights_name=$(echo "$arm_output" | jq -r '.properties.outputs.appinsights_name.value')
appinsights_key=$(az monitor app-insights component show \
    --app "$appinsights_name" \
    --resource-group "$resource_group_name" \
    --output json |
    jq -r '.instrumentationKey')
appinsights_connstr=$(az monitor app-insights component show \
    --app "$appinsights_name" \
    --resource-group "$resource_group_name" \
    --output json |
    jq -r '.connectionString')

# Store in Keyvault
az keyvault secret set --vault-name "$kv_name" --name "applicationInsightsKey" --value "$appinsights_key"
az keyvault secret set --vault-name "$kv_name" --name "applicationInsightsConnectionString" --value "$appinsights_connstr"



# ###########################
# # RETRIEVE DATABRICKS INFORMATION AND CONFIGURE WORKSPACE

# Note: SP is required because Credential Passthrough does not support ADF (MSI) as of July 2021
echo "Creating Service Principal (SP) for access to ADLS Gen2 used in Databricks mounting"

stor_id=$(az storage account show \
    --name "$azure_storage_account" \
    --resource-group "$resource_group_name" \
    --output json |
    jq -r '.id')
sp_stor_name="${PROJECT}-stor-${ENV_NAME}-${DEPLOYMENT_ID}-sp"
sp_stor_out=$(az ad sp create-for-rbac \
    --role "Storage Blob Data Contributor" \
    --scopes "$stor_id" \
    --name "$sp_stor_name" \
    --output json)

    
# store storage service principal details in Keyvault
sp_stor_id=$(echo "$sp_stor_out" | jq -r '.appId')
sp_stor_pass=$(echo "$sp_stor_out" | jq -r '.password')
sp_stor_tenant=$(echo "$sp_stor_out" | jq -r '.tenant')

echo "ADLS - Valid password obtained"


az keyvault secret set --vault-name "$kv_name" --name "spStorName" --value "$sp_stor_name"
az keyvault secret set --vault-name "$kv_name" --name "spStorId" --value "$sp_stor_id"
az keyvault secret set --vault-name "$kv_name" --name "spStorPass" --value="$sp_stor_pass" ##=handles hyphen passwords
az keyvault secret set --vault-name "$kv_name" --name "spStorTenantId" --value "$sp_stor_tenant"

echo "Generate Databricks token"
databricks_host=https://$(echo "$arm_output" | jq -r '.properties.outputs.databricks_output.value.properties.workspaceUrl')
databricks_workspace_resource_id=$(echo "$arm_output" | jq -r '.properties.outputs.databricks_id.value')
databricks_aad_token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken) # Databricks app global id
databricks_workspace_url=$(echo "$arm_output" | jq -r '.properties.outputs.databricks_output.value.properties.workspaceUrl')

databricks_workspace_name="${PROJECT}-dbw-${ENV_NAME}-${DEPLOYMENT_ID}"
databricks_complete_url="https://$databricks_workspace_url/aad/auth?has=&Workspace=/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$resource_group_name/providers/Microsoft.Databricks/workspaces/$databricks_workspace_name&WorkspaceResourceGroupUri=/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$$resource_group_name&l=en"
NC='\033[0m' # No Color
GREEN='\033[0;32m'
# Display the URL
echo -e "${GREEN}Please visit the following URL and authenticate: $databricks_complete_url${NC}"

# Prompt the user for Enter after they authenticate
read -p "Press Enter after you authenticate to the Azure Databricks workspace..."

# Use Microsoft Entra access token to generate PAT token
databricks_token=$(DATABRICKS_TOKEN=$databricks_aad_token \
    DATABRICKS_HOST=$databricks_host \
    bash -c "databricks tokens create --comment 'deployment'" | jq -r .token_value)

# Save in KeyVault
az keyvault secret set --vault-name "$kv_name" --name "databricksDomain" --value "$databricks_host"
az keyvault secret set --vault-name "$kv_name" --name "databricksToken" --value "$databricks_token"
az keyvault secret set --vault-name "$kv_name" --name "databricksWorkspaceResourceId" --value "$databricks_workspace_resource_id"

# Configure databricks (KeyVault-backed Secret scope, mount to storage via SP, databricks tables, cluster)
# NOTE: must use Microsoft Entra access token, not PAT token
DATABRICKS_TOKEN=$databricks_aad_token \
DATABRICKS_HOST=$databricks_host \
KEYVAULT_DNS_NAME=$kv_dns_name \
USER_NAME=$kv_owner_name \
KEYVAULT_RESOURCE_ID=$(echo "$arm_output" | jq -r '.properties.outputs.keyvault_resource_id.value') \
    bash -c "./scripts/configure_databricks.sh"

####################
# DATA FACTORY
databricks_folder_name="/Users/${kv_owner_name,,}"
databricks_folder_name_standardize="${databricks_folder_name}/02_standardize.py"
databricks_folder_name_transform="${databricks_folder_name}/03_transform.py"
echo "databricks_folder_name_standardize: ${databricks_folder_name_standardize}"
echo "databricks_folder_name_transform: ${databricks_folder_name_transform}"

echo "Updating Data Factory LinkedService to point to newly deployed resources (KeyVault and DataLake)."
# Create a copy of the ADF dir into a .tmp/ folder.
adfTempDir=.tmp/adf
mkdir -p $adfTempDir && cp -a adf/ .tmp/
# Update ADF LinkedServices to point to newly deployed Datalake URL, KeyVault URL, and Databricks workspace URL
tmpfile=.tmpfile
adfLsDir=$adfTempDir/linkedService
adfPlDir=$adfTempDir/pipeline
jq --arg kvurl "$kv_dns_name" '.properties.typeProperties.baseUrl = $kvurl' $adfLsDir/Ls_KeyVault_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_KeyVault_01.json
jq --arg databricksWorkspaceUrl "$databricks_host" '.properties.typeProperties.domain = $databricksWorkspaceUrl' $adfLsDir/Ls_AzureDatabricks_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_AzureDatabricks_01.json
jq --arg databricksWorkspaceResourceId "$databricks_workspace_resource_id" '.properties.typeProperties.workspaceResourceId = $databricksWorkspaceResourceId' $adfLsDir/Ls_AzureDatabricks_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_AzureDatabricks_01.json
jq --arg datalakeUrl "https://$azure_storage_account.dfs.core.windows.net" '.properties.typeProperties.url = $datalakeUrl' $adfLsDir/Ls_AdlsGen2_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_AdlsGen2_01.json
jq --arg databricks_folder_name_standardize "$databricks_folder_name_standardize" '.properties.activities[0].typeProperties.notebookPath = $databricks_folder_name_standardize' $adfPlDir/P_Ingest_MelbParkingData.json > "$tmpfile" && mv "$tmpfile" $adfPlDir/P_Ingest_MelbParkingData.json
jq --arg databricks_folder_name_transform  "$databricks_folder_name_transform" '.properties.activities[4].typeProperties.notebookPath = $databricks_folder_name_transform' $adfPlDir/P_Ingest_MelbParkingData.json > "$tmpfile" && mv "$tmpfile" $adfPlDir/P_Ingest_MelbParkingData.json

datafactory_name=$(echo "$arm_output" | jq -r '.properties.outputs.datafactory_name.value')
az keyvault secret set --vault-name "$kv_name" --name "adfName" --value "$datafactory_name"

echo $adfTempDir
# Deploy ADF artifacts
AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
RESOURCE_GROUP_NAME=$resource_group_name \
DATAFACTORY_NAME=$datafactory_name \
ADF_DIR=$adfTempDir \
    bash -c "./scripts/deploy_adf_artifacts.sh"

# ADF SP for integration tests
echo "Create Service Principal (SP) for Data Factory"
sp_adf_name="${PROJECT}-adf-${ENV_NAME}-${DEPLOYMENT_ID}-sp"
sp_adf_out=$(az ad sp create-for-rbac \
    --role "Data Factory contributor" \
    --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$resource_group_name/providers/Microsoft.DataFactory/factories/$datafactory_name" \
    --name "$sp_adf_name" \
    --output json)
sp_adf_id=$(echo "$sp_adf_out" | jq -r '.appId')
sp_adf_pass=$(echo "$sp_adf_out" | jq -r '.password')
sp_adf_tenant=$(echo "$sp_adf_out" | jq -r '.tenant')

echo "ADF - Valid password obtained"


# Save ADF SP credentials in Keyvault
az keyvault secret set --vault-name "$kv_name" --name "spAdfName" --value "$sp_adf_name"
az keyvault secret set --vault-name "$kv_name" --name "spAdfId" --value "$sp_adf_id"
az keyvault secret set --vault-name "$kv_name" --name "spAdfPass" --value="$sp_adf_pass"##=handles hyphen passwords
az keyvault secret set --vault-name "$kv_name" --name "spAdfTenantId" --value "$sp_adf_tenant"

####################
# AZDO Azure Service Connection and Variables Groups

# AzDO Azure Service Connections
PROJECT=$PROJECT \
ENV_NAME=$ENV_NAME \
RESOURCE_GROUP_NAME=$resource_group_name \
DEPLOYMENT_ID=$DEPLOYMENT_ID \
    bash -c "./scripts/deploy_azdo_service_connections_azure.sh"

# AzDO Variable Groups
PROJECT=$PROJECT \
ENV_NAME=$ENV_NAME \
AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
RESOURCE_GROUP_NAME=$resource_group_name \
AZURE_LOCATION=$AZURE_LOCATION \
KV_URL=$kv_dns_name \
DATABRICKS_TOKEN=$databricks_token \
DATABRICKS_HOST=$databricks_host \
DATABRICKS_WORKSPACE_RESOURCE_ID=$databricks_workspace_resource_id \
DATABRICKS_CLUSTER_ID=$(echo "$arm_output" | jq -r '.properties.outputs.databricks_cluster_id.value') \
SQL_SERVER_NAME=$sql_server_name \
SQL_SERVER_USERNAME=$sql_server_username \
SQL_SERVER_PASSWORD=$AZURESQL_SERVER_PASSWORD \
SQL_DW_DATABASE_NAME=$sql_dw_database_name \
AZURE_STORAGE_KEY=$azure_storage_key \
AZURE_STORAGE_ACCOUNT=$azure_storage_account \
DATAFACTORY_NAME=$datafactory_name \
SP_ADF_ID=$sp_adf_id \
SP_ADF_PASS=$sp_adf_pass \
SP_ADF_TENANT=$sp_adf_tenant \
    bash -c "./scripts/deploy_azdo_variables.sh"


####################
#####BUILD ENV FILE FROM CONFIG INFORMATION
####################

env_file=".env.${ENV_NAME}"
echo "Appending configuration to .env file."
cat << EOF >> "$env_file"

# ------ Configuration from deployment on ${TIMESTAMP} -----------
RESOURCE_GROUP_NAME=${resource_group_name}
AZURE_LOCATION=${AZURE_LOCATION}
SQL_SERVER_NAME=${sql_server_name}
SQL_SERVER_USERNAME=${sql_server_username}
SQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD}
SQL_DW_DATABASE_NAME=${sql_dw_database_name}
AZURE_STORAGE_ACCOUNT=${azure_storage_account}
AZURE_STORAGE_KEY=${azure_storage_key}
SP_STOR_NAME=${sp_stor_name}
SP_STOR_ID=${sp_stor_id}
SP_STOR_PASS=${sp_stor_pass}
SP_STOR_TENANT=${sp_stor_tenant}
DATABRICKS_HOST=${databricks_host}
DATABRICKS_TOKEN=${databricks_token}
DATAFACTORY_NAME=${datafactory_name}
APPINSIGHTS_KEY=${appinsights_key}
KV_URL=${kv_dns_name}

EOF
echo "Completed deploying Azure resources $resource_group_name ($ENV_NAME)"
