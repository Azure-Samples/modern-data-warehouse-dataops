
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
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# ENV_NAME
# AZURE_SUBSCRIPTION_ID
# AZURE_LOCATION
# RESOURCE_GROUP_NAME
# KV_URL
# SYNAPSE_SQLPOOL_SERVER
# SYNAPSE_SQLPOOL_ADMIN_USERNAME
# SYNAPSE_SQLPOOL_ADMIN_PASSWORD
# SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME
# AZURE_STORAGE_ACCOUNT
# AZURE_STORAGE_KEY
# SYNAPSE_WORKSPACE_NAME
# BIG_DATAPOOL_NAME
# LOG_ANALYTICS_WS_ID
# LOG_ANALYTICS_WS_KEY
# SP_SYNAPSE_ID
# SP_SYNAPSE_PASS
# SP_SYNAPSE_TENANT

# Const
apiBaseUrl="https://data.melbourne.vic.gov.au/resource/"

# Create vargroup
vargroup_name="${PROJECT}-release-$ENV_NAME"
if vargroup_id=$(az pipelines variable-group list -o tsv | grep "$vargroup_name" | awk '{print $3}'); then
    echo "Variable group: $vargroup_name already exists. Deleting..."
    az pipelines variable-group delete --id "$vargroup_id" -y
fi
echo "Creating variable group: $vargroup_name"
az pipelines variable-group create \
    --name "$vargroup_name" \
    --authorize "true" \
    --variables \
        azureLocation="$AZURE_LOCATION" \
        rgName="$RESOURCE_GROUP_NAME" \
        apiBaseUrl="$apiBaseUrl" \
    --output json

# Create vargroup - for secrets
vargroup_secrets_name="${PROJECT}-secrets-$ENV_NAME"
if vargroup_secrets_id=$(az pipelines variable-group list -o tsv | grep "$vargroup_secrets_name" | awk '{print $3}'); then
    echo "Variable group: $vargroup_secrets_name already exists. Deleting..."
    az pipelines variable-group delete --id "$vargroup_secrets_id" -y
fi
echo "Creating variable group: $vargroup_secrets_name"
vargroup_secrets_id=$(az pipelines variable-group create \
    --name "$vargroup_secrets_name" \
    --authorize "true" \
    --output json \
    --variables foo="bar" | jq -r .id)  # Needs at least one secret

az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "kvUrl" --value "$KV_URL"
# Datalake
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "datalakeAccountName" --value "$AZURE_STORAGE_ACCOUNT"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "datalakeKey" --value "$AZURE_STORAGE_KEY"
# Log Analytics
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "logAnalyticsWorkspaceId" --value "$LOG_ANALYTICS_WS_ID"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "logAnalyticsWorkspaceKey" --value "$LOG_ANALYTICS_WS_KEY"

# Synapse SQL Dedicated Pool (formerly SQL DW)
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "synapseSqlPoolServer" --value "$SYNAPSE_SQLPOOL_SERVER"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
   --secret "true" --name "synapseSqlPoolAdminUsername" --value "$SYNAPSE_SQLPOOL_ADMIN_USERNAME"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "synapseSqlPoolAdminPassword" --value "$SYNAPSE_SQLPOOL_ADMIN_PASSWORD"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "synapseDedicatedSqlPoolDBName" --value "$SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME"
# Synapse
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "synapseWorkspaceName" --value "$SYNAPSE_WORKSPACE_NAME"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "synapseSparkPoolName" --value "$BIG_DATAPOOL_NAME"

# Service Principal for Synapse Integration Testing
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "spSynapseId" --value "$SP_SYNAPSE_ID"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "spSynapsePass" --value "$SP_SYNAPSE_PASS"
az pipelines variable-group variable create --group-id "$vargroup_secrets_id" \
    --secret "true" --name "spSynapseTenantId" --value "$SP_SYNAPSE_TENANT"

# Delete dummy vars
az pipelines variable-group variable delete --group-id "$vargroup_secrets_id" --name "foo" -y
