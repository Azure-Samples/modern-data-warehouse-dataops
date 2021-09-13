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
# SYNAPSE_WORKSPACE_NAME
# BIG_DATAPOOL_NAME
# LOG_ANALYTICS_WS_ID
# LOG_ANALYTICS_WS_KEY

# Consts
apiVersion="2021-03-01&force=true"
baseUrl="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}"
synapseWorkspaceBaseUrl="$baseUrl/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Synapse/workspaces/${SYNAPSE_WORKSPACE_NAME}"
echo $synapseWorkspaceBaseUrl

synapse_ws_location=$(az group show \
    --name "${RESOURCE_GROUP_NAME}" \
    --output json |
    jq -r '.location')
synapse_spark_config_body="{\"location\": \" $synapse_ws_location \", \"properties\": { \"sparkVersion\": \"2.4\", \"nodeCount\": 10, \"nodeSize\": \"Small\", \"nodeSizeFamily\": \"MemoryOptimized\", \"sparkConfigProperties\": {\"configurationType\": 0, \"filename\": \"spark_loganalytics_conf.txt\", \"content\": \"spark.synapse.logAnalytics.enabled true\r\nspark.synapse.logAnalytics.workspaceId ${LOG_ANALYTICS_WS_ID}\r\nspark.synapse.logAnalytics.secret ${LOG_ANALYTICS_WS_KEY}\"}}}"
echo $synapse_spark_config_body

uploadSynapseSparkConfiguration () {
    declare name=$1
    echo "Uploading Spark Configuration: $name"
    synapseBigDataPoolUri="${synapseWorkspaceBaseUrl}/bigDataPools/${BIG_DATAPOOL_NAME}?api-version=${apiVersion}"
    az rest --method put --headers "Content-Type=application/json" --uri "$synapseBigDataPoolUri" --body "$synapse_spark_config_body"
}

uploadSynapseSparkConfiguration "Log Analytics"