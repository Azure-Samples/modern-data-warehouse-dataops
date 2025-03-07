
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

#!/bin/bash

. ./infrastructure/common.sh
# Source environment variables
source .env

#Prompt login.
#if more than one subscription, choose the one that will be used to deploy the resources.

#Check variables are set for login.

if [ -z "${TENANT_ID:-}" ] || [ -z "${AZURE_SUBSCRIPTION_ID:-}" ]; then
    log "To run this script the following environment variables are required." "danger"
    log "Check if your .env file contains values for variables: \nTENANT_ID, AZURE_SUBSCRIPTION_ID" "danger"
    exit 1
fi

# Check if already logged in, it will logout first

if az account show > /dev/null 2>&1; then
    log "Already logged in. Logging out and logging in again."
    az logout
fi

az config set core.login_experience_v2=off
az login --tenant $TENANT_ID
az config set core.login_experience_v2=on
az account set -s $AZURE_SUBSCRIPTION_ID  -o none

if [ -z "$AZURE_SUBSCRIPTION_ID" ]
then
    log "Please specify an Azure Subscription ID using the [AZURE_SUBSCRIPTION_ID] environment variable." "danger"
    exit 1
fi


# initialize optional variables.

DEPLOYMENT_ID=${DEPLOYMENT_ID:-}
if [ -z "$DEPLOYMENT_ID" ]
then
    export DEPLOYMENT_ID="$(random_str 5)"
    log "No deployment id [DEPLOYMENT_ID] specified, defaulting to $DEPLOYMENT_ID" "info"
fi

AZURE_LOCATION=${AZURE_LOCATION:-}
if [ -z "$AZURE_LOCATION" ]
then
    export AZURE_LOCATION="westus2"
    log "No resource group location [AZURE_LOCATION] specified, defaulting to $AZURE_LOCATION" "info"
fi

ENABLE_KEYVAULT_SOFT_DELETE=${ENABLE_KEYVAULT_SOFT_DELETE:-}
if [ -z "$ENABLE_KEYVAULT_SOFT_DELETE" ]
then
    # set soft delete variable to true if the env variable has not been set
    export ENABLE_KEYVAULT_SOFT_DELETE=${ENABLE_KEYVAULT_SOFT_DELETE:-true}
    log "No ENABLE_KEYVAULT_SOFT_DELETE specified. Defaulting to $ENABLE_KEYVAULT_SOFT_DELETE" "info"
fi

ENABLE_KEYVAULT_PURGE_PROTECTION=${ENABLE_KEYVAULT_PURGE_PROTECTION:-}
if [ -z "$ENABLE_KEYVAULT_PURGE_PROTECTION" ]
then
    # set purge protection variable to true if the env variable has not been set
    export ENABLE_KEYVAULT_PURGE_PROTECTION=${ENABLE_KEYVAULT_PURGE_PROTECTION:-true}
    log "No ENABLE_KEYVAULT_PURGE specified. Defaulting to $ENABLE_KEYVAULT_PURGE_PROTECTION" "info"
fi

PROJECT="${PROJECT_NAME:-}"
ENV_NAME=dev
DEPLOYMENT_ID=$DEPLOYMENT_ID
TEAM_NAME="${TEAM_NAME:-}"
###################
# AZURE_LOCATION
# REQUIRED ENV VARIABLES:
#
# PROJECT
# DEPLOYMENT_ID
# ENV_NAME
# AZURE_SUBSCRIPTION_ID

#####################
### DEPLOY ARM TEMPLATE
#####################

log "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID" "info"

# Create resource group
resource_group_name="$PROJECT-$DEPLOYMENT_ID-$ENV_NAME-rg"
log "Creating resource group: $resource_group_name"
az group create --name "$resource_group_name" --location "$AZURE_LOCATION" --tags Environment="$ENV_NAME" TeamName="$TEAM_NAME" -o none

# Create security group
security_group_name="$PROJECT-$DEPLOYMENT_ID-$ENV_NAME-sg"
log "Creating security group: $security_group_name"
az ad group create --display-name "$security_group_name" --mail-nickname "$security_group_name"
security_group_id=$(az ad group show --group "$security_group_name" -o json | jq -r '.id')

# Add self to security group
log "Adding self to security group: $security_group_id"
az ad group member add --group "$security_group_name" --member-id "$(az ad signed-in-user show --output json | jq -r '.id')"

# By default, set all KeyVault permission to deployer
# Retrieve KeyVault User Id
kv_owner_object_id=$(az ad signed-in-user show --output json | jq -r '.id')
kv_owner_name=$(az ad user show --id "$kv_owner_object_id" --output json | jq -r '.userPrincipalName')

# Handle KeyVault Soft Delete and Purge Protection
kv_name="$PROJECT-kv-$ENV_NAME-$DEPLOYMENT_ID"
log "Checking if the KeyVault name $kv_name can be used..."
kv_list=$(az keyvault list-deleted -o json --query "[?contains(name,'$kv_name')]")

if [[ $(echo "$kv_list" | jq -r '.[0]') != null ]]; then
    log "Existing Soft-Deleted KeyVault found: $kv_name. This script will try to replace it." "warning"
    kv_purge_protection_enabled=$(echo "$kv_list" | jq -r '.[0].properties.purgeProtectionEnabled') #can be null or true
    kv_purge_scheduled_date=$(echo "$kv_list" | jq -r '.[0].properties.scheduledPurgeDate')
    # If purge protection is enabled and scheduled date is in the future, then we can't create a new KeyVault with the same name
    if [[ $kv_purge_protection_enabled == true && $kv_purge_scheduled_date > $(date -u +"%Y-%m-%dT%H:%M:%SZ") ]]; then
        log "Existing Soft-Deleted KeyVault has Purge Protection enabled. Scheduled Purge Date: $kv_purge_scheduled_date."$'\n'"As it is not possible to proceed, please change your deployment id."$'\n'"Exiting..." "danger"
        exit 1
    else
        # if purge scheduled date is not in the future or purge protection was not enabled, then ask if user wants to purge the keyvault
        read -p "Deleted KeyVault with the same name exists but can be purged. Do you want to purge the existing KeyVault?"$'\n'"Answering YES will mean you WILL NOT BE ABLE TO RECOVER the old KeyVault and its contents. Answer [y/N]: " response

        case "$response" in
            [yY][eE][sS]|[yY])
            az keyvault purge --name "$kv_name" --no-wait
            ;;
            *)
            log "You selected not to purge the existing KeyVault. Please change deployment id. Exiting..." "danger"
            exit 1
            ;;
        esac
    fi
fi

# Handle SQL Server and Database
sql_server_name="$PROJECT-sql-$ENV_NAME-$DEPLOYMENT_ID"
sql_db_name="$PROJECT-sqldb-$ENV_NAME-$DEPLOYMENT_ID"
ip_address=$(curl -4 icanhazip.com)

# Validate arm template
log "Validating deployment"
arm_output=$(az deployment group validate \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" deployment_id="${DEPLOYMENT_ID}" \
    --parameters keyvault_name="${kv_name}" enable_keyvault_soft_delete="${ENABLE_KEYVAULT_SOFT_DELETE}" \
    --parameters enable_keyvault_purge_protection="${ENABLE_KEYVAULT_PURGE_PROTECTION}"\
    --parameters sql_server_name="${sql_server_name}" sql_db_name="${sql_db_name}" ip_address="${ip_address}" \
    --parameters aad_group_name="${security_group_name}" aad_group_object_id="${security_group_id}" team_name="${TEAM_NAME}"\
    --output json)

# Deploy arm template
log "Deploying resources into $resource_group_name"
arm_output=$(az deployment group create \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" deployment_id="${DEPLOYMENT_ID}" \
    --parameters keyvault_name="${kv_name}" enable_keyvault_soft_delete="${ENABLE_KEYVAULT_SOFT_DELETE}" \
    --parameters enable_keyvault_purge_protection="${ENABLE_KEYVAULT_PURGE_PROTECTION}"\
    --parameters sql_server_name="${sql_server_name}" sql_db_name="${sql_db_name}" ip_address="${ip_address}" \
    --parameters aad_group_name="${security_group_name}" aad_group_object_id="${security_group_id}" team_name="${TEAM_NAME}"\
    --output json)

if [[ -z $arm_output ]]; then
    log "ARM deployment failed." "danger"
    exit 1
fi


########################
# RETRIEVE KEYVAULT INFORMATION

log "Retrieving KeyVault information from the deployment."

kv_dns_name=https://${kv_name}.vault.azure.net/

# Store in KeyVault
az keyvault secret set --vault-name "$kv_name" --name "kvUrl" --value "$kv_dns_name" -o none
az keyvault secret set --vault-name "$kv_name" --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID" -o none


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
log "Creating ADLS Gen2 File system: $storage_file_system"
az storage container create --name $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none
az storage container create --name input-documents --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none --public-access container
az storage container create --name di-results --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none --public-access container

# log "Creating folders within the file system."
# # Create folders for databricks libs
# az storage fs directory create -n '/sys/databricks/libs' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none
# # Create folders for SQL external tables
# az storage fs directory create -n '/data/dw/fact_parking' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none
# az storage fs directory create -n '/data/dw/dim_st_marker' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none
# az storage fs directory create -n '/data/dw/dim_parking_bay' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none
# az storage fs directory create -n '/data/dw/dim_location' -f $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" -o none

# log "Uploading seed data to data/seed"
# az storage blob upload --container-name $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" \
#     --file data/seed/dim_date.csv --name "data/seed/dim_date/dim_date.csv" --overwrite -o none
# az storage blob upload --container-name $storage_file_system --account-name "$azure_storage_account" --account-key "$azure_storage_key" \
#     --file data/seed/dim_time.csv --name "data/seed/dim_time/dim_time.csv" --overwrite -o none

# Set Keyvault secrets
az keyvault secret set --vault-name "$kv_name" --name "datalakeAccountName" --value "$azure_storage_account" -o none
az keyvault secret set --vault-name "$kv_name" --name "datalakeKey" --value "$azure_storage_key" -o none
az keyvault secret set --vault-name "$kv_name" --name "datalakeurl" --value "https://$azure_storage_account.dfs.core.windows.net" -o none

####################
# APPLICATION INSIGHTS

# temporary, move to .devcontainer
az extension add --name application-insights

log "Retrieving ApplicationInsights information from the deployment."
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
az keyvault secret set --vault-name "$kv_name" --name "applicationInsightsKey" --value "$appinsights_key" -o none
az keyvault secret set --vault-name "$kv_name" --name "applicationInsightsConnectionString" --value "$appinsights_connstr" -o none

# ###########################
# # RETRIEVE DATABRICKS INFORMATION AND CONFIGURE WORKSPACE

# Note: SP is required because Credential Passthrough does not support ADF (MSI) as of July 2021
log "Creating Service Principal (SP) for access to ADLS Gen2 used in Databricks mounting"

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

az keyvault secret set --vault-name "$kv_name" --name "spStorName" --value "$sp_stor_name" -o none
az keyvault secret set --vault-name "$kv_name" --name "spStorId" --value "$sp_stor_id" -o none
az keyvault secret set --vault-name "$kv_name" --name "spStorPass" --value="$sp_stor_pass" -o none ##=handles hyphen passwords
az keyvault secret set --vault-name "$kv_name" --name "spStorTenantId" --value "$sp_stor_tenant" -o none

log "Generate Databricks token"
databricks_host=https://$(echo "$arm_output" | jq -r '.properties.outputs.databricks_output.value.properties.workspaceUrl')
databricks_workspace_resource_id=$(echo "$arm_output" | jq -r '.properties.outputs.databricks_id.value')
databricks_aad_token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken) # Databricks app global id
databricks_workspace_url=$(echo "$arm_output" | jq -r '.properties.outputs.databricks_output.value.properties.workspaceUrl')

databricks_workspace_name="${PROJECT}-dbw-${ENV_NAME}-${DEPLOYMENT_ID}"
databricks_complete_url="https://$databricks_workspace_url/aad/auth?has=&Workspace=/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$resource_group_name/providers/Microsoft.Databricks/workspaces/$databricks_workspace_name&WorkspaceResourceGroupUri=/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$$resource_group_name&l=en"

# Display the URL
log "Please visit the following URL and authenticate: $databricks_complete_url" "action"

# Prompt the user for Enter after they authenticate
read -p "Press Enter after you authenticate to the Azure Databricks workspace..."

# Use Microsoft Entra access token to generate PAT token
databricks_token=$(DATABRICKS_TOKEN=$databricks_aad_token \
    DATABRICKS_HOST=$databricks_host \
    bash -c "databricks tokens create --comment 'deployment'" | jq -r .token_value)

# Save in KeyVault
az keyvault secret set --vault-name "$kv_name" --name "databricksDomain" --value "$databricks_host" -o none
az keyvault secret set --vault-name "$kv_name" --name "databricksToken" --value "$databricks_token" -o none
az keyvault secret set --vault-name "$kv_name" --name "databricksWorkspaceResourceId" --value "$databricks_workspace_resource_id" -o none

# Configure databricks (KeyVault-backed Secret scope, mount to storage via SP, databricks tables, cluster)
# NOTE: must use Microsoft Entra access token, not PAT token
DATABRICKS_TOKEN=$databricks_aad_token \
DATABRICKS_HOST=$databricks_host \
KEYVAULT_DNS_NAME=$kv_dns_name \
USER_NAME=$kv_owner_name \
AZURE_LOCATION=$AZURE_LOCATION \
KEYVAULT_RESOURCE_ID=$(echo "$arm_output" | jq -r '.properties.outputs.keyvault_resource_id.value') \
STORAGE_CONN_STRING=$(echo "$arm_output" | jq -r '.properties.outputs.storage_conn_string.value') \
    bash -c "./infrastructure/configure_databricks.sh"

####################
# AZDO Azure Service Connection and Variables Groups

# # AzDO Azure Service Connections
# PROJECT=$PROJECT \
# ENV_NAME=$ENV_NAME \
# RESOURCE_GROUP_NAME=$resource_group_name \
# DEPLOYMENT_ID=$DEPLOYMENT_ID \
#     bash -c "./scripts/deploy_azdo_service_connections_azure.sh"

# # AzDO Variable Groups
# PROJECT=$PROJECT \
# ENV_NAME=$ENV_NAME \
# AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
# RESOURCE_GROUP_NAME=$resource_group_name \
# AZURE_LOCATION=$AZURE_LOCATION \
# KV_URL=$kv_dns_name \
# DATABRICKS_TOKEN=$databricks_token \
# DATABRICKS_HOST=$databricks_host \
# DATABRICKS_WORKSPACE_RESOURCE_ID=$databricks_workspace_resource_id \
# DATABRICKS_CLUSTER_ID=$(echo "$arm_output" | jq -r '.properties.outputs.databricks_cluster_id.value') \
# SQL_SERVER_NAME=$sql_server_name \
# SQL_SERVER_USERNAME=$sql_server_username \
# SQL_SERVER_PASSWORD=$AZURESQL_SERVER_PASSWORD \
# SQL_DW_DATABASE_NAME=$sql_dw_database_name \
# AZURE_STORAGE_KEY=$azure_storage_key \
# AZURE_STORAGE_ACCOUNT=$azure_storage_account \
# DATAFACTORY_ID=$datafactory_id \
# DATAFACTORY_NAME=$datafactory_name \
# SP_ADF_ID=$sp_adf_id \
# SP_ADF_PASS=$sp_adf_pass \
# SP_ADF_TENANT=$sp_adf_tenant \
#     bash -c "./scripts/deploy_azdo_variables.sh"


# ####################
# #####BUILD ENV FILE FROM CONFIG INFORMATION
# ####################

# env_file=".env.${ENV_NAME}"
# log "Appending configuration to .env file." "info"
# cat << EOF >> "$env_file"

# # ------ Configuration from deployment on ${TIMESTAMP} -----------
# RESOURCE_GROUP_NAME=${resource_group_name}
# AZURE_LOCATION=${AZURE_LOCATION}
# SQL_SERVER_NAME=${sql_server_name}
# SQL_SERVER_USERNAME=${sql_server_username}
# SQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD}
# SQL_DW_DATABASE_NAME=${sql_dw_database_name}
# AZURE_STORAGE_ACCOUNT=${azure_storage_account}
# AZURE_STORAGE_KEY=${azure_storage_key}
# SP_STOR_NAME=${sp_stor_name}
# SP_STOR_ID=${sp_stor_id}
# SP_STOR_PASS=${sp_stor_pass}
# SP_STOR_TENANT=${sp_stor_tenant}
# DATABRICKS_HOST=${databricks_host}
# DATABRICKS_TOKEN=${databricks_token}
# DATAFACTORY_NAME=${datafactory_name}
# APPINSIGHTS_KEY=${appinsights_key}
# KV_URL=${kv_dns_name}

log "Completed deploying Azure resources $resource_group_name ($ENV_NAME)" "success"
