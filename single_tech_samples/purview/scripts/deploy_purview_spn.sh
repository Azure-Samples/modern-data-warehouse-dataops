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
# Deploys Purview Service Principal 
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
# DEPLOYMENT_ID
# PURVIEW_ACCOUNT_NAME

###############
# Setup Azure Service Principal

az_sub=$(az account show --output json)
az_sub_id=$(echo $az_sub | jq -r '.id')
az_sub_name=$(echo $az_sub | jq -r '.name')

scope="/subscriptions/${az_sub_id}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Purview/accounts/${PURVIEW_ACCOUNT_NAME}"

# Create Service Account
az_sp_name=mdwdo-adf-${ENV_NAME}-${DEPLOYMENT_ID}-purview-sp
echo "Creating service principal: $az_sp_name for azure service connection"
az_sp=$(az ad sp create-for-rbac \
    --role owner \
    --scopes $scope \
    --name $az_sp_name \
    --output json)
export PURVIEW_SPN_APP_ID=$(echo $az_sp | jq -r '.appId')
az_sp_tenant_id=$(echo $az_sp | jq -r '.tenant')

# Create Azure Service connection in Azure DevOps
export PURVIEW_SPN_APP_KEY=$(echo $az_sp | jq -r '.password')

az role assignment create --assignee $PURVIEW_SPN_APP_ID --role "Purview Data Source Administrator" --scope $scope
az role assignment create --assignee $PURVIEW_SPN_APP_ID --role "Purview Data Curator" --scope $scope
