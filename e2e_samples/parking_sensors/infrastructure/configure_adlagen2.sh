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
# Configure ADLA Gen2 Service Principal permissions
#
# This script performs the following:
# 1. Create Service Principle for ADLS Gen2
# 2. Grant correct RBAC role to the SP
# 3. Create File System using REST API
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

################
# PARAMETERS
################
rg_name="${1-}"
storage_account="${2-}"
sp_stor_id="${3-}"
sp_stor_pass="${4-}"
sp_stor_tenantid="${5-}"

storage_fs=datalake # Constant

# Retrieve full storage account azure id
storage_account_id=$(az storage account show \
    --name "$storage_account" \
    --resource-group "$rg_name" \
    --output json |
    jq -r '.id')

# See this issue: https://github.com/Azure/azure-powershell/issues/2286
# TODO: make more robust
sleep 1m 

# Grant "Storage Blob Data Owner (Preview)
echo "Granting 'Storage Blob Data Contributor' for '$storage_account' to SP"
az role assignment create --assignee "$sp_stor_id" \
    --role "Storage Blob Data Contributor" \
    --scope "$storage_account_id"

# Because ADLA Gen2 is not yet supported by the az cli 2.0 as of 2019/02/04
# we resort to calling the REST API directly:
# https://docs.microsoft.com/en-us/rest/api/storageservices/datalakestoragegen2/filesystem
#
# For information on calling Azure REST API, see here: 
# https://docs.microsoft.com/en-us/rest/api/azure/

# It takes time for AD permissions to propogate
# TODO: make more robust
sleep 2m

# Use service principle to generate bearer token
bearer_token=$(curl -X POST -d "grant_type=client_credentials&client_id=${sp_stor_id}&client_secret=${sp_stor_pass}&resource=https%3A%2F%2Fstorage.azure.com%2F" \
    https://login.microsoftonline.com/${sp_stor_tenantid}/oauth2/token |
    jq -r '.access_token')

# Use bearer token to create file system
echo "Creating ADLA Gen2 File System '$storage_fs' in storage account: '$storage_account'"
curl -X PUT -d -H 'Content-Type:application/json' -H "Authorization: Bearer ${bearer_token}" \
    https://${storage_account}.dfs.core.windows.net/${storage_fs}?resource=filesystem

echo "Completed configuring ADLA Gen2."