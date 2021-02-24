
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
# DATAFACTORY_NAME
# AZURE_SUBSCRIPTION_ID
# DL_STORAGE_ACCOUNT
# DL_STORAGE_KEY
# FS_STORAGE_ACCOUNT
# FS_STORAGE_KEY

# Create vargroup
vargroup_name="mdwdo-adf-release-$ENV_NAME"
echo "Creating variable group: $vargroup_name"
az pipelines variable-group create \
    --name "$vargroup_name" \
    --authorize "true" \
    --variables \
        azureLocation="$RESOURCE_GROUP_LOCATION" \
        rgName="$RESOURCE_GROUP_NAME" \
        adfName="$DATAFACTORY_NAME" \
    --output json

# Create vargroup - for secrets
vargroup_secrets_name="mdwdo-adf-release-secrets-$ENV_NAME"
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
# Datalake
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "datalakeAccountName" --value "$DL_STORAGE_ACCOUNT"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "datalakeKey" --value "$DL_STORAGE_KEY"
# FileShare
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "fileshareAccountName" --value "$FS_STORAGE_ACCOUNT"
az pipelines variable-group variable create --group-id $vargroup_secrets_id \
    --secret "true" --name "fileshareKey" --value "$FS_STORAGE_KEY"

# Delete dummy vars
az pipelines variable-group variable delete --group-id $vargroup_secrets_id --name "foo" -y