
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
# set -o xtrace # For debugging

# REQUIRED VARIABLES:
# RG_NAME - resource group name
# RG_LOCATION - resource group location (ei. australiaeast)
# GITHUB_REPO_URL - Github URL
# GITHUB_PAT_TOKEN - Github PAT Token
# AZURESQL_SRVR_PASSWORD - Password for the sqlAdmin account

# Helper functions
random_str() {
    local length=$1
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1
    return 0
}


# Create resource group
echo "Creating resource group $RG_NAME"
az group create --name $RG_NAME --location $RG_LOCATION


###############
# Deploy AzureSQL
echo "Deploying resources into $RG_NAME"
arm_output=$(az group deployment create \
    --resource-group "$RG_NAME" \
    --template-file "./infrastructure/azuredeploy.json" \
    --parameters "azuresql_srvr_password=${AZURESQL_SRVR_PASSWORD}" \
    --output json)


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
    --scopes /subscriptions/$az_sub_id/resourceGroups/$RG_NAME \
    --name $az_sp_name \
    --output json)
az_sp_id=$(echo $az_sp | jq -r '.appId')
az_sp_tenand_id=$(echo $az_sp | jq -r '.tenant')

# Create Azure Service connection in Azure DevOps
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$(echo $az_sp | jq -r '.password')
az_service_connection_name=azure-mdw-dataops
echo "Creating Azure service connection: $az_service_connection_name in Azure DevOps"
az devops service-endpoint azurerm create \
    --name "$az_service_connection_name" \
    --azure-rm-service-principal-id "$az_sp_id" \
    --azure-rm-subscription-id "$az_sub_id" \
    --azure-rm-subscription-name "$az_sub_name" \
    --azure-rm-tenant-id "$az_sp_tenand_id"


###############
# Setup Github service connection

export AZURE_DEVOPS_EXT_GITHUB_PAT=$GITHUB_PAT_TOKEN
github_service_connection_name=github-mdw-dataops
echo "Creating Github service connection: $github_service_connection_name in Azure DevOps"
github_service_connection_id=$(az devops service-endpoint github create \
    --name "$github_service_connection_name" \
    --github-url "$GITHUB_REPO_URL" \
    --output json | jq -r '.id')


###############
# Deploy Pipelines: validate pr

azuresql_validate_pr_pipeline_name=azuresql-validate-pr
echo "Creating Pipeline: $azuresql_validate_pr_pipeline_name in Azure DevOps"
az pipelines create \
    --name "$azuresql_validate_pr_pipeline_name" \
    --description 'This pipelines validates pull requests to master' \
    --repository "$GITHUB_REPO_URL" \
    --branch master \
    --yaml-path 'single_tech_samples/azuresql/pipelines/azure-pipelines-validate-pr.yml' \
    --service-connection "$github_service_connection_id"


###############
# Deploy Pipelines: build

azuresql_build_pipeline_name=azuresql-build
echo "Creating Pipeline: $azuresql_build_pipeline_name in Azure DevOps"
az pipelines create \
    --name "$azuresql_build_pipeline_name" \
    --description 'This pipelines build the DACPAC and publishes it as a Build Artifact' \
    --repository "$GITHUB_REPO_URL" \
    --branch master \
    --yaml-path 'single_tech_samples/azuresql/pipelines/azure-pipelines-build.yml' \
    --service-connection "$github_service_connection_id"


###############
# Deploy Pipelines: simple multi-stage

# Create pipeline
azuresql_simple_multi_stage_pipeline_name=azuresql-simple-multi-stage
echo "Creating Pipeline: $azuresql_build_pipeline_name in Azure DevOps"
simple_multistage_pipeline_id=$(az pipelines create \
    --name $azuresql_simple_multi_stage_pipeline_name \
    --description 'This pipelines is a simpe two stage pipeline which builds the DACPAC and deploy to a target AzureSQLDB instance' \
    --repository $GITHUB_REPO_URL \
    --branch master \
    --yaml-path 'single_tech_samples/azuresql/pipelines/azure-pipelines-simple-multi-stage.yml' \
    --service-connection $github_service_connection_id \
    --skip-first-run true \
    --output json | jq -r '.id')

# Create Variables
azuresql_srvr_name=$(echo $arm_output | jq -r '.properties.outputs.azuresql_srvr_name.value')
az pipelines variable create \
    --name AZURESQL_SERVER_NAME \
    --pipeline-id $simple_multistage_pipeline_id \
    --value $azuresql_srvr_name

azuresql_db_name=$(echo $arm_output | jq -r '.properties.outputs.azuresql_db_name.value')
az pipelines variable create \
    --name AZURESQL_DB_NAME \
    --pipeline-id $simple_multistage_pipeline_id \
    --value $azuresql_db_name

azuresql_srvr_admin=$(echo $arm_output | jq -r '.properties.outputs.azuresql_srvr_admin.value')
az pipelines variable create \
    --name AZURESQL_SERVER_USERNAME \
    --pipeline-id $simple_multistage_pipeline_id \
    --value $azuresql_srvr_admin

azuresql_srvr_password=$(echo $arm_output | jq -r '.properties.outputs.azuresql_srvr_password.value')
az pipelines variable create \
    --name AZURESQL_SERVER_PASSWORD \
    --pipeline-id $simple_multistage_pipeline_id \
    --secret true \
    --value $azuresql_srvr_password

az pipelines run --name $azuresql_simple_multi_stage_pipeline_name

echo "Done!"