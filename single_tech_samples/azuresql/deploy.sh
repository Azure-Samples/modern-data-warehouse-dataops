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
# Deploys azuresql samples. 
# See README for prerequisites.
#######################################################

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace # For debugging

# REQUIRED VARIABLES:
# RESOURCE_GROUP_NAME - resource group name
# RESOURCE_GROUP_LOCATION - resource group location (ei. australiaeast)
# GITHUB_REPO_URL - Github URL
# GITHUB_PAT_TOKEN - Github PAT Token
# AZURESQL_SRVR_PASSWORD - Password for the sqlAdmin account

. ./scripts/common.sh

# Create resource group
echo "Creating resource group $RESOURCE_GROUP_NAME"
az group create --name $RESOURCE_GROUP_NAME --location $RESOURCE_GROUP_LOCATION


###############
# Setup Azure service connection

# Retrieve azure sub information
az_sub=$(az account show --output json)
az_sub_id=$(echo $az_sub | jq -r '.id')
az_sub_name=$(echo $az_sub | jq -r '.name')

# Create Service Account
az_sp_name=sp_dataops_$(random_str 5)
echo "Creating service principal: $az_sp_name for azure service connection"
az_sp=$(az ad sp create-for-rbac \
    --role contributor \
    --scopes /subscriptions/$az_sub_id/resourceGroups/$RESOURCE_GROUP_NAME \
    --name $az_sp_name \
    --output json)
az_sp_id=$(echo $az_sp | jq -r '.appId')
az_sp_tenand_id=$(echo $az_sp | jq -r '.tenant')

# Create Azure Service connection in Azure DevOps
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$(echo $az_sp | jq -r '.password')
echo "Creating Azure service connectionn Azure DevOps"
az devops service-endpoint azurerm create \
    --name "azure-mdw-dataops" \
    --azure-rm-service-principal-id "$az_sp_id" \
    --azure-rm-subscription-id "$az_sub_id" \
    --azure-rm-subscription-name "$az_sub_name" \
    --azure-rm-tenant-id "$az_sp_tenand_id"


###############
# Setup Github service connection

export AZURE_DEVOPS_EXT_GITHUB_PAT=$GITHUB_PAT_TOKEN
echo "Creating Github service connection in Azure DevOps"
export GITHUB_SERVICE_CONNECTION_ID=$(az devops service-endpoint github create \
    --name "github-mdw-dataops" \
    --github-url "$GITHUB_REPO_URL" \
    --output json | jq -r '.id')

###############
# Deploy pipelines

./scripts/deploy_azure_pipelines_01_validate_pr.sh
./scripts/deploy_azure_pipelines_02_build.sh
./scripts/deploy_azure_pipelines_03_simple_multi_stage.sh
./scripts/deploy_azure_pipelines_04_multi_stage_predeploy_test.sh


# ####################
# # BUILD ENV FILE FROM CONFIG INFORMATION

# timestamp=$(date +"%Y%m%d%H%M%S")
# env_file=.$timestamp.env

# echo "Appending configuration to .env file: $env_file"
# cat << EOF >> $env_file

# # ------ Configuration from deployment on ${timestamp} -----------
# RESOURCE_GROUP=${RESOURCE_GROUP_NAME}
# RESOURCE_GROUP_LOCATION=${RESOURCE_GROUP_LOCATION}

# AZURESQL_SERVER_NAME_SIMPLE_MULTISTAGE=${simple_multistage_sqlsrvr_name}
# AZURESQL_SERVER_ADMIN=${azuresql_srvr_admin}
# AZURESQL_SERVER_PASSWORD=${AZURESQL_SRVR_PASSWORD}

# AZURESQL_SERVER_NAME_MULTISTAGE_PREDEPLOY=${multistage_predeploy_sqlsrvr_name}

# SERVICE_PRINCIPAL_NAME=${az_sp_name}
# SERVICE_PRINCIPAL_ID=${az_sp_id}
# SERVICE_PRINCIPAL_PASSWORD=${AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY}
# SERVICE_PRINCIPAL_TENANT=${az_sp_tenand_id}

# EOF
# echo "Completed deploying AzureSQL DataOps sample!"
