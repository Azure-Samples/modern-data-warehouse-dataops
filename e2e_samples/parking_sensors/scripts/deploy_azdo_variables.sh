
#!/bin/bash

#######################################################
# Deploys Azure DevOps Variable Groups
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
# - Correct Azure DevOps Project selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# ENV_NAME
# AZURE_SUBSCRIPTION_ID
# AZURE_LOCATION
# RESOURCE_GROUP_NAME
# KV_URL
# API_BASE_URL
# KV_NAME
# DATABRICKS_HOST
# DATABRICKS_TOKEN
# DATABRICKS_WORKSPACE_RESOURCE_ID
# DATABRICKS_CLUSTER_ID
# SQL_SERVER_NAME
# SQL_SERVER_USERNAME
# SQL_SERVER_PASSWORD
# SQL_DW_DATABASE_NAME
# AZURE_STORAGE_ACCOUNT
# AZURE_STORAGE_KEY
# DATAFACTORY_ID
# DATAFACTORY_NAME
# SP_ADF_ID
# SP_ADF_PASS
# SP_ADF_TENANT

. ./scripts/common.sh

# Const
if [ "$ENV_NAME" == "dev" ]
then 
    # In DEV, we fix the path to "dev" folder  to simplify as this is manual publish DEV ADF.
    databricksLibPath='/releases/dev/libs'
    databricksNotebookPath='/releases/dev/notebooks'
else
    databricksLibPath='/releases/$(Build.BuildId)/libs'
    databricksNotebookPath='/releases/$(Build.BuildId)/notebooks'
fi

databricksClusterId=$(az keyvault secret show --name "databricksClusterId" --vault-name "$KV_NAME" --query "value" -o tsv)

# Create vargroup
vargroup_name="${PROJECT}-release-$ENV_NAME"
if vargroup_id=$(az pipelines variable-group list -o json | jq -r -e --arg vg_name "$vargroup_name" '.[] | select(.name==$vg_name) | .id'); then
    log "Variable group: $vargroup_name already exists. Deleting..." "info"
    az pipelines variable-group delete --id "$vargroup_id" -y  -o none
fi
log "Creating variable group: $vargroup_name" "info"
az pipelines variable-group create \
    --name "$vargroup_name" \
    --authorize "true" \
    --variables \
        azureLocation="$AZURE_LOCATION" \
        rgName="$RESOURCE_GROUP_NAME" \
        adfName="$DATAFACTORY_NAME" \
        databricksLibPath="$databricksLibPath" \
        databricksNotebookPath="$databricksNotebookPath" \
        databricksClusterId="$databricksClusterId" \
        apiBaseUrl="$API_BASE_URL" \
    -o none
# databricksDbfsLibPath="$databricksDbfsLibPath" \

# Create vargroup - for secrets
vargroup_secrets_name="${PROJECT}-secrets-$ENV_NAME"
if vargroup_secrets_id=$(az pipelines variable-group list -o json | jq -r -e --arg vg_name "$vargroup_secrets_name" '.[] | select(.name==$vg_name) | .id'); then
    log "Variable group: $vargroup_secrets_name already exists. Deleting..." "info"
    az pipelines variable-group delete --id "$vargroup_secrets_id" -y -o none
fi
log "Creating variable group: $vargroup_secrets_name" "info"
vargroup_secrets_id=$(az pipelines variable-group create \
    --name "$vargroup_secrets_name" \
    --authorize "true" \
    --output tsv \
    --variables foo="bar" \
    --query "id")  # Needs at least one secret

az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "kvUrl" --value "$KV_URL"  -o none
# sql server
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "sqlsrvrName" --value "$SQL_SERVER_NAME"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "sqlsrvrUsername" --value "$SQL_SERVER_USERNAME"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "sqlsrvrPassword" --value "$SQL_SERVER_PASSWORD"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "sqlDwDatabaseName" --value "$SQL_DW_DATABASE_NAME"  -o none
# Databricks
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "databricksDomain" --value "$DATABRICKS_HOST"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "databricksToken" --value "$DATABRICKS_TOKEN"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "databricksWorkspaceResourceId" \
    --value "$DATABRICKS_WORKSPACE_RESOURCE_ID"  -o none
# Datalake
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "datalakeAccountName" --value "$AZURE_STORAGE_ACCOUNT"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "datalakeKey" --value "$AZURE_STORAGE_KEY"  -o none
# Adf
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "spAdfId" --value "$SP_ADF_ID"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "spAdfPass" --value "$SP_ADF_PASS"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "spAdfTenantId" --value "$SP_ADF_TENANT"  -o none
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "adfResourceId" --value "$DATAFACTORY_ID"  -o none
    
# Delete dummy vars
az pipelines variable-group variable delete --group-id "$vargroup_secrets_id" --name "foo" -y  -o none