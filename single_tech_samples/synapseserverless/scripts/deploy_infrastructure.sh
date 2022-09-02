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
owner_object_id=$(az ad signed-in-user show --output json | jq -r '.id')

# Validate arm template
echo "Validating deployment"
arm_output=$(az deployment group validate \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters project="${PROJECT}" deployment_id="${DEPLOYMENT_ID}" \
    --output json)

# Deploy arm template
echo "Deploying resources into $resource_group_name"
arm_output=$(az deployment group create \
    --resource-group "$resource_group_name" \
    --template-file "./infrastructure/main.bicep" \
    --parameters project="${PROJECT}" deployment_id="${DEPLOYMENT_ID}" \
    --output json)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed."
    exit 1
fi


####################
# SYNAPSE ANALYTICS

echo "Retrieving Synapse Analytics information from the deployment."
synapseworkspace_name=$(echo "$arm_output" | jq -r '.properties.outputs.synapseworskspace_name.value')
synapse_serverless_endpoint=$(az synapse workspace show \
    --name "$synapseworkspace_name" \
    --resource-group "$resource_group_name" \
    --output json |
    jq -r '.connectivityEndpoints | .sqlOnDemand')

# The server name of connection string will be the same as Synapse worspace name
synapse_sqlpool_server=$(echo "$arm_output" | jq -r '.properties.outputs.synapseworskspace_name.value')

echo "$owner_object_id"
# Grant Synapse Administrator to the deployment owner
assign_synapse_role_if_not_exists "$synapseworkspace_name" "Synapse Administrator" "$owner_object_id"
#assign_synapse_role_if_not_exists "$synapseworkspace_name" "Synapse SQL Administrator" "$owner_object_id"