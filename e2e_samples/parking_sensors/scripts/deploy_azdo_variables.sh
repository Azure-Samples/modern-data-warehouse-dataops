
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
# ENV_NAME
# RESOURCE_GROUP_LOCATION
# RESOURCE_GROUP_NAME
# DATABRICKS_HOST
# DATABRICKS_TOKEN
# SQL_SERVER_NAME
# SQL_SERVER_USERNAME
# SQL_SERVER_PASSWORD
# SQL_DW_DATABASE_NAME
# STORAGE_ACCOUNT
# STORAGE_KEY
# DATAFACTORY_NAME

# Const
apiBaseUrl="https://data.melbourne.vic.gov.au/resource/"
if [ $ENV_NAME == "dev" ]
then 
    # In DEV, we fix the path to "dev" folder  to simplify as this is manual publish DEV ADF.
    # In other environments, the ADF release pipeline overwrites these automatically.
    databricksDbfsLibPath="dbfs:/mnt/datalake/sys/databricks/libs/dev/"
    databricksNotebookPath='/releases/dev/'
else
    databricksDbfsLibPath='dbfs:/mnt/datalake/sys/databricks/libs/$(Build.BuildId)'
    databricksNotebookPath='/releases/$(Build.BuildId)'
fi

# Create vargroup
vargroup_name="mdwdo-park-release-$ENV_NAME"
echo "Creating variable group: $vargroup_name"
az pipelines variable-group create \
    --name "$vargroup_name" \
    --authorize "true" \
    --variables \
        azureLocation="$RESOURCE_GROUP_LOCATION" \
        rgName="$RESOURCE_GROUP_NAME" \
        adfName="$DATAFACTORY_NAME" \
        databricksDbfsLibPath="$databricksDbfsLibPath" \
        databricksNotebookPath="$databricksNotebookPath" \
        apiBaseUrl="$apiBaseUrl" \
    --output json

# Create vargroup - for secrets
vargroup_secrets_name="mdwdo-park-release-secrets-$ENV_NAME"
echo "Creating variable group: $vargroup_secrets_name"
vargroup_secrets_id=$(az pipelines variable-group create \
    --name "$vargroup_secrets_name" \
    --authorize "true" \
    --output json \
    --variables foo="bar" | jq -r .id)

az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "kvUrl" --value "$KV_URL"
# sql server
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "sqlsrvrName" --value "$SQL_SERVER_NAME"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "sqlsrvrUsername" --value "$SQL_SERVER_USERNAME"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "sqlsrvrPassword" --value "$SQL_SERVER_PASSWORD"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "sqlDwDatabaseName" --value "$SQL_DW_DATABASE_NAME"
# Databricks
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "databricksDomain" --value "$DATABRICKS_HOST"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "databricksToken" --value "$DATABRICKS_TOKEN"
# Datalake
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "datalakeAccountName" --value "$AZURE_STORAGE_ACCOUNT"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "datalakeKey" --value "$AZURE_STORAGE_KEY"
# Adf
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "spAdfId" --value "$SP_ADF_ID"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "spAdfPass" --value "$SP_ADF_PASS"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "spAdfTenantId" --value "$SP_ADF_TENANT"


# Delete dummy vars
az pipelines variable-group variable delete --group-id $vargroup_secrets_id --name "foo" -y