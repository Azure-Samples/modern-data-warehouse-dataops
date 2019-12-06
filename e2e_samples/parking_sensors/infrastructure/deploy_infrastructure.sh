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

###################
# PARAMETERS

env_name="${1-}"
rg_name="${2-}"
rg_location="${3-}"
sub_id="${4-}"
kvOwnerObjectId="${5-}"

env_file="../.env.${env_name}"

# Set path
parent_dir=$(pwd -P)
dir_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P ); cd "$dir_path"


#####################
# DEPLOY ARM TEMPLATE

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $sub_id"
az account set --subscription $sub_id

# Create resource group
echo "Creating resource group: $rg_name"
az group create --name "$rg_name" --location "$rg_location"

# Deploy arm template
echo "Deploying resources into $rg_name"
arm_output=$(az group deployment create \
    --resource-group "$rg_name" \
    --template-file "./azuredeploy.json" \
    --parameters @"./azuredeploy.parameters.${env_name}.json" \
    --parameters "kvOwnerObjectId=${kvOwnerObjectId}" \
    --output json)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed." 
    exit 1
fi

###########################
# RETRIEVE DATABRICKS INFORMATION

# Ask user to configure databricks cli
# TODO: see if this can be automated
dbricks_name=$(echo $arm_output | jq -r '.properties.outputs.dbricksName.value')
echo -e "${ORANGE}"
echo "Configure your databricks cli to connect to the newly created Databricks workspace: ${dbricks_name}. See here for more info: https://bit.ly/2GUwHcw."
databricks configure --token
echo -e "${NC}"

# Databricks token and details
dbricks_location=$(echo $arm_output | jq -r '.properties.outputs.dbricksLocation.value')
dbi_token=$(awk '/token/ && NR==3 {print $0;exit;}' ~/.databrickscfg | cut -d' ' -f3)
[[ -n $dbi_token ]] || { echo >&2 "Databricks cli not configured correctly. Please run databricks configure --token. Aborting."; exit 1; }


#########################
# RETRIEVE CONFIG INFORMATION

# Retrieve KeyVault details
kv_name=$(echo $arm_output | jq -r '.properties.outputs.kvName.value')

# Retrieve storage account (ADLS Gen2) details
storage_account=$(echo $arm_output | jq -r '.properties.outputs.storName.value')
storage_account_key=$(az storage account keys list \
    --account-name $storage_account \
    --resource-group $rg_name \
    --output json |
    jq -r '.[0].value')

# Retrieve SP name for ADLA Gen2 from arm output
sp_stor_name=$(echo $arm_output | jq -r '.properties.outputs.spStorName.value')


#########################
# CREATE AND CONFIGURE SERVICE PRINCIPAL FOR ADLA GEN2

echo "Creating Service Principal (SP) for access to ADLA Gen2: '$sp_stor_name'"
sp_stor_out=$(az ad sp create-for-rbac --name $sp_stor_name \
    --skip-assignment \
    --output json)
sp_stor_id=$(echo $sp_stor_out | jq -r '.appId')
sp_stor_pass=$(echo $sp_stor_out | jq -r '.password')
sp_stor_tenantid=$(echo $sp_stor_out | jq -r '.tenant')

. ./configure_adlagen2.sh "$rg_name" "$storage_account" "$sp_stor_id" "$sp_stor_pass" "$sp_stor_tenantid"


####################
# SAVE RELEVANT SECRETS IN KEYVAULT

az keyvault secret set --vault-name $kv_name --name "storageAccount" --value $storage_account
az keyvault secret set --vault-name $kv_name --name "storageKey" --value $storage_account_key
az keyvault secret set --vault-name $kv_name --name "spStorName" --value $sp_stor_name
az keyvault secret set --vault-name $kv_name --name "spStorId" --value $sp_stor_id
az keyvault secret set --vault-name $kv_name --name "spStorPass" --value $sp_stor_pass
az keyvault secret set --vault-name $kv_name --name "spStorTenantId" --value $sp_stor_tenantid
az keyvault secret set --vault-name $kv_name --name "dbricksDomain" --value https://${dbricks_location}.azuredatabricks.net
az keyvault secret set --vault-name $kv_name --name "dbricksToken" --value $dbi_token


####################
# BUILD ENV FILE FROM CONFIG INFORMATION

echo "Appending configuration to .env file."
cat << EOF >> $env_file

# ------ Configuration from deployment on ${TIMESTAMP} -----------
RESOURCE_GROUP=${rg_name}
BLOB_STORAGE_ACCOUNT=${storage_account}
BLOB_STORAGE_KEY=${storage_account_key}
SP_STOR_NAME=${sp_stor_name}
SP_STOR_ID=${sp_stor_id}
SP_STOR_PASS=${sp_stor_pass}
SP_STOR_TENANT=${sp_stor_tenantid}
KV_NAME=${kv_name}
DATABRICKS_HOST=https://${dbricks_location}.azuredatabricks.net
DATABRICKS_TOKEN=${dbi_token}

EOF
echo "Completed deploying Azure resources $rg_name ($env_name)"


echo "Return to parent script dir: $parent_dir"
cd "$parent_dir"