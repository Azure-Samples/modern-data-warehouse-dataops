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
# Deploys ADF artifacts
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# AZURE_SUBSCRIPTION_ID
# RESOURCE_GROUP_NAME
# DATAFACTORY_NAME

# Consts
apiVersion="2018-06-01"
adfBaseUrl="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DataFactory/factories/${DATAFACTORY_NAME}"
adfDir="adf"

# Overwrite values
# Create .tmp
tmp=.tmpfile
jq --arg kvurl "$KV_URL" '.properties.typeProperties.baseUrl = $kvurl' $adfDir/Ls_KeyVault_01.json > "$tmp" && mv "$tmp" Ls_KeyVault_01.json
jq --arg datalakeUrl "https://$AZURE_STORAGE_ACCOUNT.dfs.core.windows.net" '.properties.typeProperties.url = $datalakeUrl' $adfDir/Ls_AdlsGen2_01.json > "$tmp" && mv "$tmp" Ls_AdlsGen2_01.json

# Deploy all Linked Services
createLinkedService () {
    declare name=$1
    adfLsUrl="${adfBaseUrl}/linkedservices/${name}?api-version=${apiVersion}"
    az rest --method put --uri $adfLsUrl --body @${adfDir}/linkedService/${name}.json
}
createLinkedService "Ls_KeyVault_01"
createLinkedService "Ls_AdlsGen2_01"
createLinkedService "Ls_AzureSQLDW_01"
createLinkedService "Ls_AzureDatabricks_01"
createLinkedService "Ls_Rest_MelParkSensors_01"

# Deploy all Datasets
createDataset () {
    declare name=$1
    adfDsUrl="${adfBaseUrl}/datasets/${name}?api-version=${apiVersion}"
    az rest --method put --uri $adfDsUrl --body @${adfDir}/dataset/${name}.json
}
createDataset "Ds_AdlsGen2_MelbParkingData"
createDataset "Ds_REST_MelbParkingData"

# Deploy all Pipelines
createPipeline () {
    declare name=$1
    adfPUrl="${adfBaseUrl}/pipelines/${name}?api-version=${apiVersion}"
    az rest --method put --uri $adfPUrl --body @${adfDir}/pipeline/${name}.json
}
createPipeline "P_Ingest_MelbParkingData"

# Deploy triggers
createTrigger () {
    declare name=$1
    adfTUrl="${adfBaseUrl}/triggers/${name}?api-version=${apiVersion}"
    az rest --method put --uri $adfTUrl --body @${adfDir}/trigger/${name}.json
}
createTrigger "T_Sched"