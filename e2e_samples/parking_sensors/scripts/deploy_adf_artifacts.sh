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
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# AZURE_SUBSCRIPTION_ID
# RESOURCE_GROUP_NAME
# DATAFACTORY_NAME
# ADF_DIR


# Consts
apiVersion="2018-06-01"
baseUrl="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}"
adfFactoryBaseUrl="$baseUrl/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DataFactory/factories/${DATAFACTORY_NAME}"


createLinkedService () {
    declare name=$1
    echo "Creating ADF LinkedService: $name"
    adfLsUrl="${adfFactoryBaseUrl}/linkedservices/${name}?api-version=${apiVersion}"
    az rest --method put --uri $adfLsUrl --body @${ADF_DIR}/linkedService/${name}.json
}
createDataset () {
    declare name=$1
    echo "Creating ADF Dataset: $name"
    adfDsUrl="${adfFactoryBaseUrl}/datasets/${name}?api-version=${apiVersion}"
    az rest --method put --uri $adfDsUrl --body @${ADF_DIR}/dataset/${name}.json
}
createPipeline () {
    declare name=$1
    echo "Creating ADF Pipeline: $name"
    adfPUrl="${adfFactoryBaseUrl}/pipelines/${name}?api-version=${apiVersion}"
    az rest --method put --uri $adfPUrl --body @${ADF_DIR}/pipeline/${name}.json
}
createTrigger () {
    declare name=$1
    echo "Creating ADF Trigger: $name"
    adfTUrl="${adfFactoryBaseUrl}/triggers/${name}?api-version=${apiVersion}"
    az rest --method put --uri $adfTUrl --body @${ADF_DIR}/trigger/${name}.json
}

echo "Deploying Data Factory artifacts."

# Deploy all Linked Services
createLinkedService "Ls_KeyVault_01"
createLinkedService "Ls_AdlsGen2_01"
createLinkedService "Ls_AzureSQLDW_01"
createLinkedService "Ls_AzureDatabricks_01"
createLinkedService "Ls_Rest_MelParkSensors_01"
# Deploy all Datasets
createDataset "Ds_AdlsGen2_MelbParkingData"
createDataset "Ds_REST_MelbParkingData"
# Deploy all Pipelines
createPipeline "P_Ingest_MelbParkingData"
# Deploy triggers
createTrigger "T_Sched"

echo "Completed deploying Data Factory artifacts."

############################
# Setup git integration
# LACE: unfortunately, there doesn't seem to be a way to trigger "import existing resources into Collaboration branch" when we setup Git integration manually.

# # Commit changes to the LinkedServices
# git checkout -b $COLLABORATION_BRANCH
# git add $adfLsDir/Ls_KeyVault_01.json
# git add $adfLsDir/Ls_AdlsGen2_01.json
# git commit -m "fix: [deploy script] update Linked Service URL to point to correct DEV environment."
# git push

# adfRepoUrl="$baseUrl/providers/Microsoft.DataFactory/locations/${RESOURCE_GROUP_LOCATION}/configureFactoryRepo?api-version=${apiVersion}"

# body=$(jq -n \
#     --arg frid "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.DataFactory/factories/$DATAFACTORY_NAME" \
#     --arg an "$GITHUB_ACCOUNT_NAME" \
#     --arg cb "$COLLABORATION_BRANCH" \
#     --arg repo "$REPOSITORY_NAME" \
#     --arg rfolder "/e2e_samples/parking_sensors/adf" \
#     --arg rtype "FactoryGitHubConfiguration" \
#     '{"factoryResourceId": $frid, "repoConfiguration": {"accountName": $an, "collaborationBranch": $cb, "repositoryName": $repo, "rootFolder": $rfolder, "type": $rtype }}')

# az rest --method post --uri $adfRepoUrl --body "$body"
