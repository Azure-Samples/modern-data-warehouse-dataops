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
# set -o xtrace # For debugging

# REQUIRED VARIABLES:
# GITHUB_REPO_URL - Github URL
# GITHUB_PAT_TOKEN - Github PAT Token

# OPTIONAL VARIABLES
# DEPLOYMENT_ID - Identifier to append to names of resource created for this deployment. Resources will also be tagged with this. Defaults to generated string.
# BRANCH_NAME - Branch that pipelines will be deployed for. Defaults to main.
# AZURESQL_SERVER_PASSWORD - Password for the sqlAdmin account. Defaults to generated value.
# RESOURCE_GROUP_NAME - resource group name
# RESOURCE_GROUP_LOCATION - resource group location (ei. australiaeast)

. ./scripts/common.sh
. ./scripts/init_environment.sh

if [ -z $BRANCH_NAME ]
then 
    echo "No working branch name specified, defaulting to main"
    export BRANCH_NAME='main'
fi

# Create resource group
echo "Creating resource group $RESOURCE_GROUP_NAME"
az group create --name $RESOURCE_GROUP_NAME --location $RESOURCE_GROUP_LOCATION
az group update --name $RESOURCE_GROUP_NAME --tags "source=mdwdo-azsql" "deployment=$DEPLOYMENT_ID"

###############
# Setup Azure service connection

# Retrieve azure sub information
az_sub=$(az account show --output json)
export AZURE_SUBSCRIPTION_ID=$(echo $az_sub | jq -r '.id')
az_sub_name=$(echo $az_sub | jq -r '.name')

# Create Service Account
az_sp_name=mdwdo-azsql-${DEPLOYMENT_ID}-sp
echo "Creating service principal: $az_sp_name for azure service connection"
az_sp=$(az ad sp create-for-rbac \
    --role contributor \
    --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME \
    --name $az_sp_name \
    --output json)
export SERVICE_PRINCIPAL_ID=$(echo $az_sp | jq -r '.appId')
az_sp_tenant_id=$(echo $az_sp | jq -r '.tenant')

#tags don't seem to work right on service principals at the moment.
az ad sp update --id $SERVICE_PRINCIPAL_ID --add tags "source=mdwdo-azsql"
az ad sp update --id $SERVICE_PRINCIPAL_ID --add tags "deployment=$DEPLOYMENT_ID"

# Create Azure Service connection in Azure DevOps
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$(echo $az_sp | jq -r '.password')
echo "Creating Azure service connection Azure DevOps"
az devops service-endpoint azurerm create \
    --name "mdwdo-azsql" \
    --azure-rm-service-principal-id "$SERVICE_PRINCIPAL_ID" \
    --azure-rm-subscription-id "$AZURE_SUBSCRIPTION_ID" \
    --azure-rm-subscription-name "$az_sub_name" \
    --azure-rm-tenant-id "$az_sp_tenant_id"


###############
# Setup Github service connection

export AZURE_DEVOPS_EXT_GITHUB_PAT=$GITHUB_PAT_TOKEN
echo "Creating Github service connection in Azure DevOps"
export GITHUB_SERVICE_CONNECTION_ID=$(az devops service-endpoint github create \
    --name "mdwdo-azsql-github" \
    --github-url "$GITHUB_REPO_URL" \
    --output json | jq -r '.id')

###############
# Deploy pipelines

./scripts/deploy_azure_pipelines_01_validate_pr.sh
./scripts/deploy_azure_pipelines_02_build.sh
./scripts/deploy_azure_pipelines_03_simple_multi_stage.sh
./scripts/deploy_azure_pipelines_04_multi_stage_predeploy_test.sh

echo "Completed deployment ${DEPLOYMENT_ID}"

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
# AZURESQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD}

# AZURESQL_SERVER_NAME_MULTISTAGE_PREDEPLOY=${multistage_predeploy_sqlsrvr_name}

# SERVICE_PRINCIPAL_NAME=${az_sp_name}
# SERVICE_PRINCIPAL_ID=${SERVICE_PRINCIPAL_ID}
# SERVICE_PRINCIPAL_PASSWORD=${AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY}
# SERVICE_PRINCIPAL_TENANT=${az_sp_tenant_id}

# EOF
# echo "Completed deploying AzureSQL DataOps sample!"
