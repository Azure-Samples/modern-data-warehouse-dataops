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

getProvisioningState(){
    provision_state=$(az synapse spark pool show \
    --name "$BIG_DATAPOOL_NAME" \
    --workspace-name "$SYNAPSE_WORKSPACE_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --only-show-errors \
    --output json |
    jq -r '.provisioningState')
}

createLinkedService () {
    declare name=$1
    declare url=$2
    echo "$(date):Synapse Workspace: Creating Synapse LinkedService: $name"
    tmp=$(mktemp)

    case "$name" in
        "Ls_NYCTaxi_Synapse_Serverless_master" | "Ls_NYCTaxi_Synapse_Serverless_db")
            # Replace connection string
            jqfilter=".properties.typeProperties.connectionString = \"${url}\""
            ;;
        "Ls_NYCTaxi_KeyVault")
            # Replace baseurl
            jqfilter=".properties.typeProperties.baseUrl = \"${url}\""
            ;;
        *)
            jqfilter=".properties.typeProperties.url = \"${url}\""
            ;;
    esac

    jq "$jqfilter" ./synapseartifacts/workspace/linkedservices/"${name}".json > "$tmp" && mv "$tmp" ./synapseartifacts/workspace/linkedservices/"${name}".json

    az synapse linked-service create --file @./synapseartifacts/workspace/linkedservices/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}" -o none
}

createDataset () {
    declare name=$1
    echo "$(date):Synapse Workspace: Creating Synapse Dataset: $name"
    az synapse dataset create --file @./synapseartifacts/workspace/datasets/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}" -o none
}
createNotebook() {
    declare name=$1
    # As of 26 Oct 2021, there is an outstanding bug regarding az synapse notebook create command which prevents it from deploy notebook .JSON files
    # Thus, we are resorting to deploying notebooks in .ipynb format.
    # See here: https://github.com/Azure/azure-cli/issues/20037
    echo "$(date):Synapse Workspace: Creating Synapse Notebook: $name"
    az synapse notebook create --file @./synapseartifacts/notebooks/"${name}".ipynb --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}" -o none
}
createPipeline () {
    declare name=$1
    declare sqlScript=$2
    echo "$(date):Synapse Workspace: Creating Synapse Pipeline: $name"

    case $name in 
        "Pl_NYCTaxi_1_Setup")
             # Replace sql script link to create external data source based on deployment info
            tmp=$(mktemp)
            jq --arg a "${sqlScript}" '.properties.activities[1].typeProperties.scripts[0].text = $a' ./synapseartifacts/workspace/pipelines/"${name}".json > "$tmp" && mv "$tmp" ./synapseartifacts/workspace/pipelines/"${name}".json
            ;;
        "Pl_NYCTaxi_2_IngestData")
            # Replace spark pool name based on deployment info
            tmp=$(mktemp)
            jq --arg a "${PROJECT_NAME}st1${DEPLOYMENT_ID}" '.properties.activities[1].typeProperties.parameters.stgAccountName.value = $a' ./synapseartifacts/workspace/pipelines/"${name}".json > "$tmp" && mv "$tmp" ./synapseartifacts/workspace/pipelines/"${name}".json
            
            tmp1=$(mktemp)
            jq --arg a "${BIG_DATAPOOL_NAME}" '.properties.activities[1].typeProperties.sparkPool.referenceName = $a' ./synapseartifacts/workspace/pipelines/"${name}".json > "$tmp1" && mv "$tmp1" ./synapseartifacts/workspace/pipelines/"${name}".json
            ;;
        "Pl_NYCTaxi_0_Main")
            tmp=$(mktemp)
            jq --arg a "${PROJECT_NAME}st1${DEPLOYMENT_ID}" '.properties.activities[3].typeProperties.parameters.storage_acct.value = $a' ./synapseartifacts/workspace/pipelines/"${name}".json > "$tmp" && mv "$tmp" ./synapseartifacts/workspace/pipelines/"${name}".json

            tmp1=$(mktemp)
            jq --arg a "${BIG_DATAPOOL_NAME}" '.properties.activities[3].typeProperties.sparkPool.referenceName = $a' ./synapseartifacts/workspace/pipelines/"${name}".json > "$tmp1" && mv "$tmp1" ./synapseartifacts/workspace/pipelines/"${name}".json
            ;;
        "Pl_NYCTaxi_Run_Data_Retention")
            # Replace spark pool name and storage account name based on deployment info
            tmp=$(mktemp)
            jq --arg a "${PROJECT_NAME}st1${DEPLOYMENT_ID}" '.properties.activities[1].typeProperties.activities[0].typeProperties.ifFalseActivities[0].typeProperties.parameters.stgAccountName.value = $a' ./synapseartifacts/workspace/pipelines/"${name}".json > "$tmp" && mv "$tmp" ./synapseartifacts/workspace/pipelines/"${name}".json
            
            tmp1=$(mktemp)
            jq --arg a "${BIG_DATAPOOL_NAME}" '.properties.activities[1].typeProperties.activities[0].typeProperties.ifFalseActivities[0].typeProperties.sparkPool.referenceName = $a' ./synapseartifacts/workspace/pipelines/"${name}".json > "$tmp1" && mv "$tmp1" ./synapseartifacts/workspace/pipelines/"${name}".json
            ;;
    esac

    # Deploy the pipeline
    az synapse pipeline create --file @./synapseartifacts/workspace/pipelines/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}" -o none
}
createTrigger () {
    declare name=$1
    echo "$(date):Synapse Workspace: Creating Synapse Trigger: $name"
    az synapse trigger create --file @./synapseartifacts/workspace/triggers/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}" -o none
}

createSQLScript(){
    declare name=$1
    echo "$(date):Synapse Workspace: Creating Synapse SQL Script: $name"
    az synapse sql-script create --workspace-name $SYNAPSE_WORKSPACE_NAME --name "${name}" --file ./synapseartifacts/workspace/scripts/"$name".sql -o none
}

startTrigger(){
    declare name=$1
    echo "$(date):Synapse Workspace: Starting Synapse Trigger: $name"
    az synapse trigger start --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --name "${name}"
}

getProvisioningState
echo "$(date):$provision_state"

while [ "$provision_state" != "Succeeded" ]
do
    if [ "$provision_state" == "Failed" ]; then break ; else sleep 10; fi
    getProvisioningState
    echo "$provision_state: checking again in 10 seconds..."
done

addPackageToSynapseWorkspace(){
    echo "$(date):Synapse Workspace: Adding Wheel file as a workspace package"
    az synapse workspace-package upload --workspace-name "${SYNAPSE_WORKSPACE_NAME}" \
        --package ./synapseartifacts/workspace/workspace_packages/adlsaccess-1.0-py3-none-any.whl
}

attachPackageToSparkPool(){
    echo "$(date):Synapse SparkPool Update: Attaching workspace package to SparkPool"
    az synapse spark pool update --name "${BIG_DATAPOOL_NAME}" \
        --workspace-name "${SYNAPSE_WORKSPACE_NAME}" \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --package "adlsaccess-1.0-py3-none-any.whl" \
        --package-action Add
}

# Add Wheel package to Synapse workspace
addPackageToSynapseWorkspace
attachPackageToSparkPool

# Deploy all Linked Services

createLinkedService "Ls_NYCTaxi_KeyVault" "https://${KEYVAULT_NAME}.vault.azure.net/"
createLinkedService "Ls_NYCTaxi_HTTP" "https://d37ci6vzurychx.cloudfront.net/trip-data/"
createLinkedService "Ls_NYCTaxi_ADLS2" "https://${PROJECT_NAME}st1${DEPLOYMENT_ID}.dfs.core.windows.net/"
createLinkedService "Ls_NYCTaxi_Synapse_Serverless_master" "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${SYNAPSE_WORKSPACE_NAME}-ondemand.sql.azuresynapse.net;Initial Catalog=master"
createLinkedService "Ls_NYCTaxi_Synapse_Serverless_db" "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${SYNAPSE_WORKSPACE_NAME}-ondemand.sql.azuresynapse.net;Initial Catalog=db_serverless"
createLinkedService "Ls_NYCTaxi_Config" "https://${PROJECT_NAME}st1${DEPLOYMENT_ID}.dfs.core.windows.net/"
createLinkedService "Ls_NYCTaxi_ADLS2_Folder" "https://${PROJECT_NAME}st1${DEPLOYMENT_ID}.dfs.core.windows.net/"

# Deploy Datasets
createDataset "Ds_NYCTaxi_HTTP" 
createDataset "Ds_NYCTaxi_ADLS2"
createDataset "Ds_NYCTaxi_ADLS2_Folder"
createDataset "Ds_NYCTaxi_ADLS2_Year_Folder"
createDataset "Ds_NYCTaxi_Config"

# Deploy all Notebooks
# This line allows the spark pool to be available to attach to the notebooks
az synapse spark session list --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}" -o none
createNotebook "Nb_NYCTaxi_Convert_Parquet_to_Delta"
az synapse spark session list --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}" -o none
createNotebook "Nb_NYCTaxi_Config_Operations_Library"
az synapse spark session list --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}" -o none
createNotebook "Nb_NYCTaxi_Config_Operations_Library_No_Wheel"
az synapse spark session list --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}" -o none
createNotebook "Nb_NYCTaxi_Run_Data_Retention"
az synapse spark session list --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}" -o none
createNotebook "Nb_NYCTaxi_Run_Data_Retention_No_Wheel" -o none

# Deploy Setup Pipeline
createPipeline "Pl_NYCTaxi_1_Setup" "IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'ext_ds_datalake') BEGIN CREATE EXTERNAL DATA SOURCE [ext_ds_datalake] WITH (LOCATION = N'https://${PROJECT_NAME}st1${DEPLOYMENT_ID}.blob.core.windows.net/datalake') END"

# Deploy main pipeline that transforms parquet to delta and created dynamic views on top of the delta structure
createPipeline "Pl_NYCTaxi_2_IngestData" "${BIG_DATAPOOL_NAME}"

# Deploy main pipeline that calls the setup and ingest  pipelines
createPipeline "Pl_NYCTaxi_0_Main" ""

createPipeline "Pl_NYCTaxi_Run_Data_Retention" "${BIG_DATAPOOL_NAME}"

# Deploy trigger
createTrigger "Tg_NYCTaxi_0_Main"

# Deploy SQL Script
createSQLScript "Sc_Column_Level_Security" 

# Start trigger
startTrigger "Tg_NYCTaxi_0_Main"