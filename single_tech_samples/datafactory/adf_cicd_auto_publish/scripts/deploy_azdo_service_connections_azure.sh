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
# Deploys Azure DevOps Azure Service Connections
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
# RESOURCE_GROUP_NAME
# DEPLOYMENT_ID
# AZURE_DEVOPS_ORG
# AZURE_DEVOPS_PROJECT
# AZURE_DEVOPS_EXT_PAT

az_service_connection_name="mdws-adf-serviceconnection-$ENV_NAME"

az_sub=$(az account show --output json)
az_sub_id=$(echo $az_sub | jq -r '.id')
az_sub_name=$(echo $az_sub | jq -r '.name')

# Adding Azure DevOps Extension
# az extension add --name azure-devops

# Create Service Account
az_sp_name=mdws-adf-${ENV_NAME}-${DEPLOYMENT_ID}-sp
echo "Creating service principal: $az_sp_name for azure service connection"
az_sp=$(az ad sp create-for-rbac \
    --role contributor \
    --scopes "/subscriptions/${az_sub_id}/resourceGroups/${RESOURCE_GROUP_NAME}" \
    --name $az_sp_name \
    --output json)


export SERVICE_PRINCIPAL_ID=$(echo $az_sp | jq -r '.appId')
echo $AZURE_DEVOPS_EXT_PAT | az devops login --organization https://dev.azure.com/manjitsin/
az_sp_tenant_id=$(echo $az_sp | jq -r '.tenant')

az devops configure --defaults organization=https://dev.azure.com/$AZURE_DEVOPS_ORG project=$AZURE_DEVOPS_PROJECT

# Create Azure Service connection in Azure DevOps

export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$(echo $az_sp | jq -r '.password')
echo "Creating Azure service connection Azure DevOps"

# Setup Azure service connection

sc_id=$(az devops service-endpoint azurerm create \
    --name "$az_service_connection_name" \
    --azure-rm-service-principal-id "$SERVICE_PRINCIPAL_ID" \
    --azure-rm-subscription-id "$az_sub_id" \
    --azure-rm-subscription-name "$az_sub_name" \
    --azure-rm-tenant-id "$az_sp_tenant_id" --output json | jq -r '.id')

az devops service-endpoint update \
    --id $sc_id \
    --enable-for-all "true"

export AZ_SERVICE_CONNECTION_NAME=$az_service_connection_name