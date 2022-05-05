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
# Deploys Purview Lined services
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
# PURVIEW_SPN_APP_ID
# PURVIEW_SPN_APP_KEY
# DATAFACTORY_NAME
# DL_STORAGE_ACCOUNT

az_sub=$(az account show --output json)
az_sub_id=$(echo $az_sub | jq -r '.id')

###############
# Link ADF to Purview

catalogAPI="${PURVIEW_ACCOUNT_NAME}.catalog.purview.azure.com"

dataFactory=$(az resource show \
         --name $DATAFACTORY_NAME \
         --resource-group $RESOURCE_GROUP_NAME \
         --resource-type "Microsoft.DataFactory/factories")

dataFactoryManagedIdentity=$(echo $dataFactory | jq -r '.identity.principalId')
dataFactoryResourceId=$(echo $dataFactory | jq -r '.id')

# Grant ADF MSI Purview Data Curator rights to Purview
az role assignment create \
        --assignee-object-id $dataFactoryManagedIdentity  \
        --role "Purview Data Curator" \
        --scope "/subscriptions/$az_sub_id/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Purview/accounts/${PURVIEW_ACCOUNT_NAME}"

# Link ADF and Purview via tag
az tag create --resource-id $dataFactoryResourceId --tags catalogUri=$catalogAPI

###############
# Link ADL to Purview

# Grant Purview MSI Storage Data Reader rights to ADL
purviewManagedIdentity=$(az resource show \
         --name $PURVIEW_ACCOUNT_NAME \
         --resource-group $RESOURCE_GROUP_NAME \
         --resource-type "Microsoft.Purview/accounts" | jq -r '.identity.principalId' )

az role assignment create \
        --assignee-object-id $purviewManagedIdentity \
        --role "Storage Blob Data Contributor" \
        --scope "/subscriptions/$az_sub_id/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${DL_STORAGE_ACCOUNT}"

# Login to Purview REST API
export PURVIEW_ACCESS_TOKEN=$(./scripts/get_purview_access_token.sh)

echo $PURVIEW_ACCESS_TOKEN
headers="Authorization: Bearer ${PURVIEW_ACCESS_TOKEN}"
atlasAPI="https://${PURVIEW_ACCOUNT_NAME}.scan.purview.azure.com"
sourceURL="$atlasAPI/datasources/${DL_STORAGE_ACCOUNT}?api-version=2018-12-01-preview"

sourceBody='{
  "properties":{
"endpoint":"https://'${DL_STORAGE_ACCOUNT}'.dfs.core.windows.net"
  },
"kind":"AdlsGen2"
}'

# Add ADL as Source
curl -X PUT -H "$headers" --header 'Content-Type: application/json' --data "$sourceBody" --url $sourceURL

# Create Scan on new ADL Source
scanBody='{
  "properties" : {
    "scanRulesetName" : "AdlsGen2",
    "scanRulesetType" : "System"
  },
  "kind" : "AdlsGen2Msi"
}'

scanURL="$atlasAPI/datasources/${DL_STORAGE_ACCOUNT}/scans/Scan1"

curl -X PUT -H "$headers" -H 'Content-Type: application/json' -d "$scanBody" $scanURL
