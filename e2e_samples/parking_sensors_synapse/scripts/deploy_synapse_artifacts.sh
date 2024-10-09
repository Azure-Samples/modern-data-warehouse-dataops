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
# set -o xtrace # For debugging

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
# KEYVAULT_NAME
# AZURE_STORAGE_ACCOUNT

# Consts
apiVersion="2020-12-01&force=true"
dataPlaneApiVersion="2019-06-01-preview"
synapseResource="https://dev.azuresynapse.net"

baseUrl="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}"
synapseWorkspaceBaseUrl="$baseUrl/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Synapse/workspaces/${SYNAPSE_WORKSPACE_NAME}"
requirementsFileName='./synapse/config/requirements.txt'
packagesDirectory='./synapse/libs/'

synapse_ws_location=$(az group show \
    --name "${RESOURCE_GROUP_NAME}" \
    --output json |
    jq -r '.location')

addPackageToSynapseWorkspace(){ 
    declare name=$1
    echo "$(date):Synapse Workspace: Adding Wheel file as a workspace package"
    az synapse workspace-package upload --workspace-name "${SYNAPSE_WORKSPACE_NAME}" \
        --package ./synapse/libs/"${name}"
}

attachConfigsToSparkPool(){
    declare name=$1
    echo "$(date):Synapse SparkPool Update: Attaching Spark Config File to SparkPool"

    echo "$(date):Synapse SparkPool Update: Cleaning previous versions ./synapse/config/spark_config.txt"
    > ./synapse/config/spark_config.txt
    echo "" >> ./synapse/config/spark_config.txt
    
    echo "$(date):Synapse SparkPool Update: Creating current version ./synapse/config/spark_config.txt"
    echo "cleaning previous versions ./synapse/config/spark_config.txt"
    echo "spark.synapse.logAnalytics.enabled true" >> ./synapse/config/spark_config.txt
    echo "spark.synapse.logAnalytics.workspaceId ${LOG_ANALYTICS_WS_ID}" >> ./synapse/config/spark_config.txt
    echo "spark.synapse.logAnalytics.secret ${LOG_ANALYTICS_WS_KEY}" >> ./synapse/config/spark_config.txt
    echo "" >> ./synapse/config/spark_config.txt
    
    az synapse spark pool update --name "${BIG_DATAPOOL_NAME}" \
        --workspace-name "${SYNAPSE_WORKSPACE_NAME}" \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --spark-config-file-path './synapse/config/spark_config.txt' \
        --library-requirements './synapse/config/requirements.txt' \
        --package-action Add \
        --package "${name}" 
}

createLinkedService () {
    declare name=$1
    echo "Creating Synapse LinkedService: $name"
    az synapse linked-service create --file @./synapse/workspace/linkedService/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}"
}
createDataset () {
    declare name=$1
    echo "Creating Synapse Dataset: $name"
    az synapse dataset create --file @./synapse/workspace/dataset/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}"
}
createNotebook() {
    declare name=$1
    # As of 26 Oct 2021, there is an outstanding bug regarding az synapse notebook create command which prevents it from deploy notebook .JSON files
    # Thus, we are resorting to deploying notebooks in .ipynb format.
    # See here: https://github.com/Azure/azure-cli/issues/20037
    echo "Creating Synapse Notebook: $name"
    az synapse notebook create --file @./synapse/notebook/"${name}".ipynb --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}"
}
createPipeline () {
    declare name=$1
    echo "Creating Synapse Pipeline: $name"

    # Replace dedicated sql pool name
    tmp=$(mktemp)
    jq --arg a "${SQL_POOL_NAME}" '.properties.activities[5].sqlPool.referenceName = $a' ./synapse/workspace/pipeline/"${name}".json > "$tmp" && mv "$tmp" ./synapse/workspace/pipeline/"${name}".json
    # Deploy the pipeline
    az synapse pipeline create --file @./synapse/workspace/pipeline/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}"
}
createTrigger () {
    declare name=$1
    echo "Creating Synapse Trigger: $name"
    az synapse trigger create --file @./synapse/workspace/trigger/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}"
}


getProvisioningState(){
    provision_state=$(az synapse spark pool show \
    --name "$BIG_DATAPOOL_NAME" \
    --workspace-name "$SYNAPSE_WORKSPACE_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --only-show-errors \
    --output json |
    jq -r '.provisioningState')
}

UpdateExternalTableScript () {
    echo "Replace SQL script with: $AZURE_STORAGE_ACCOUNT"
    sed "s/<data storage account>/$AZURE_STORAGE_ACCOUNT/" \
    ./synapse/workspace/scripts/create_external_table_template.sql \
    > ./synapse/workspace/scripts/create_external_table.sql
}

UploadSql () {
    echo "Try to upload sql script"
    declare name=$1
    echo "Uploading sql script to Workspace: $name"

    #az synapse workspace wait --resource-group "${RESOURCE_GROUP_NAME}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --created
    # Step 1: Get bearer token for the Data plane    
    token=$(az account get-access-token --resource ${synapseResource} --query accessToken --output tsv)    
    # Step 2: create workspace package placeholder
    synapseSqlBaseUri=${SYNAPSE_DEV_ENDPOINT}/sqlScripts
    synapseSqlApiUri="${synapseSqlBaseUri}/$name?api-version=${apiVersion}"
    body_content="$(sed 'N;s/\n/\\n/' ./synapse/workspace/scripts/$name.sql)"
    json_body="{
    \"name\": \"$name\",
    \"properties\": {
        \"description\": \"$name\",        
        \"content\":{ 
            \"query\": \"$body_content\",
            \"currentConnection\": { 
                \"name\": \"master\",
                \"type\": \"SqlOnDemand\"
                }
        },
        \"metadata\": {
            \"language\": \"sql\"
        },
        \"type\": \"SqlQuery\"      
    }
    }"    
    curl -X PUT -H "Content-Type: application/json" -H "Authorization:Bearer $token" --data-raw "$json_body" --url $synapseSqlApiUri
    sleep 5
}

getProvisioningState
echo "$provision_state"

while [ "$provision_state" != "Succeeded" ]
do
    if [ "$provision_state" == "Failed" ]; then break ; else sleep 10; fi
    getProvisioningState
    echo "$provision_state: checking again in 10 seconds..."
done


# Add Wheel package to Synapse workspace
addPackageToSynapseWorkspace "ddo_transform-localdev-py2.py3-none-any.whl"
attachConfigsToSparkPool "ddo_transform-localdev-py2.py3-none-any.whl"

getProvisioningState
echo "$provision_state"
while [ "$provision_state" != "Succeeded" ]
do
    if [ "$provision_state" == "Failed" ]; then break ; else sleep 30; fi
    getProvisioningState
    echo "$provision_state: checking again in 30 seconds..."
done

# Deploy all Linked Services
# Auxiliary string to parametrize the keyvault name on the ls json file
keyVaultLsContent="{
    \"name\": \"Ls_KeyVault_01\",
    \"properties\": {
        \"annotations\": [],
        \"type\": \"AzureKeyVault\",
        \"typeProperties\": {
            \"baseUrl\": \"https://${KEYVAULT_NAME}.vault.azure.net/\"
        }
    }
}"
echo "$keyVaultLsContent" > ./synapse/workspace/linkedService/Ls_KeyVault_01.json

createLinkedService "Ls_KeyVault_01"
createLinkedService "Ls_AdlsGen2_01"
createLinkedService "Ls_Http_Parking_Bay_01"

# Deploy all Datasets
createDataset "Ds_AdlsGen2_MelbParkingData"
createDataset "Ds_Http_Parking_Bay"
createDataset "Ds_Http_Parking_Bay_Sensors"

# Deploy all Notebooks
# This line allows the spark pool to be available to attach to the notebooks
az synapse spark session list --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}"
createNotebook "00_setup"
createNotebook "01a_explore"
createNotebook "01b_explore_sqlserverless"
createNotebook "02_standardize"
createNotebook "03_transform"


# Deploy all Pipelines
createPipeline "P_Ingest_MelbParkingData"

# Deploy triggers
createTrigger "T_Sched"

# Upload SQL script
UpdateExternalTableScript
# Upload create_db_user_template for now. 
# TODO: will replace and run this sql in deploying
# TODO: will replace and run this sql in deploying
UploadSql "create_db_user_template"
UploadSql "create_external_table"
echo "Completed deploying Synapse artifacts."