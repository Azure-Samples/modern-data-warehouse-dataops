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
# Deploys Synapse artifacts
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
# SYNAPSE_WORKSPACE_NAME
# SYNAPSE_DEV_ENDPOINT
# BIG_DATAPOOL_NAME
# LOG_ANALYTICS_WS_ID
# LOG_ANALYTICS_WS_KEY

# Consts
apiVersion="2020-12-01&force=true"
dataPlaneApiVersion="2019-06-01-preview"
synapseResource="https://dev.azuresynapse.net"

baseUrl="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}"
synapseWorkspaceBaseUrl="$baseUrl/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Synapse/workspaces/${SYNAPSE_WORKSPACE_NAME}"

synapse_ws_location=$(az group show \
    --name "${RESOURCE_GROUP_NAME}" \
    --output json |
    jq -r '.location')

# uploadSynapsePackagesToWorkspace is still UNDER DEVELOPMENT
uploadSynapsePackagesToWorkspace(){
    declare name=$1
    echo "Uploading Library Wheel Package to Workspace: $name"
    RESOURCE_GROUP_NAME="ys-synapse"

    # Step 1: Get bearer token for the Data plane
    token=$(az account get-access-token --resource ${synapseResource} --query accessToken --output tsv)
    
    # Step 2: create workspace package placeholder
    synapseLibraryUri=${SYNAPSE_DEV_ENDPOINT}/libraries/${name}?api-version=${dataPlaneApiVersion}
    az rest --method put --headers 'Authorization=Bearer '${token} 'Content-Type=application/json;charset=utf-8' --url "${synapseLibraryUri}"

    # Step 3: upload package content to workspace placeholder
    #az synapse workspace wait --resource-group ${RESOURCE_GROUP_NAME} --workspace-name ${SYNAPSE_WORKSPACE_NAME} --updated
    synapseLibraryUriForAppend="${SYNAPSE_DEV_ENDPOINT}/libraries/${name}?comp=appendblock&api-version=${dataPlaneApiVersion}"
    curl -i -X PUT -H "Authorization: Bearer ${token}" -H "Content-Type: application/octet-stream" --data-binary @../synapse/libs/${name} "${synapseLibraryUriForAppend}"
  
    # Step4: Completing Package creation/Flush the library
    synapseLibraryUriForFlush="${SYNAPSE_DEV_ENDPOINT}/libraries/${name}/flush?api-version=${dataPlaneApiVersion}"
    az rest --method post --headers 'Authorization=Bearer '${token} 'Content-Type=application/json;charset=utf-8' --url "${synapseLibraryUriForFlush}"

}

uploadSynapseArtifactsToSparkPool(){
    echo "Uploading Synapse Artifacts to Spark Pool: ${BIG_DATAPOOL_NAME}"

    json_body="{
    \"location\": \"${synapse_ws_location}\",
    \"properties\": {
        \"nodeCount\": 10,
        \"isComputeIsolationEnabled\": false,
        \"nodeSizeFamily\": \"MemoryOptimized\",
        \"nodeSize\": \"Small\",
        \"autoScale\": {
            \"enabled\": true,
            \"minNodeCount\": 3,
            \"maxNodeCount\": 10
        },
        \"cacheSize\": 0,
        \"dynamicExecutorAllocation\": {
            \"enabled\": false,
            \"minExecutors\": 0,
            \"maxExecutors\": 10
        },
        \"autoPause\": {
            \"enabled\": true,
            \"delayInMinutes\": 15
        },
        \"sparkVersion\": \"2.4\",
        \"libraryRequirements\": {
            \"filename\": \"requirements.txt\",
            \"content\": \"opencensus==0.7.13\"
        },
        \"sessionLevelPackagesEnabled\": true,
        \"sparkConfigProperties\": {
            \"configurationType\": 0,
            \"filename\": \"spark_loganalytics_conf.txt\",
            \"content\": \"spark.synapse.logAnalytics.enabled true\r\nspark.synapse.logAnalytics.workspaceId ${LOG_ANALYTICS_WS_ID}\r\nspark.synapse.logAnalytics.secret ${LOG_ANALYTICS_WS_KEY}\"
        },
    }
}"
    
    #Get bearer token for the management API
    managementApiUri="${synapseWorkspaceBaseUrl}/bigDataPools/${BIG_DATAPOOL_NAME}?api-version=${apiVersion}"
    az account get-access-token
    
    #Update the Spark Pool with requirements.txt and sparkconfiguration
    az rest --method put --headers 'Content-Type=application/json' --url "${managementApiUri}" --body "$json_body"
}

uploadSynapseArtifactsToSparkPool