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
# SQL_POOL_NAME
# KEYVAULT_NAME
# KEYVAULT_ENDPOINT
# AZURE_STORAGE_ACCOUNT
# PIPELINE_NAME
# TRIGGER_NAME


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
createDataflow () {
    declare name=$1
    echo "Creating Synapse Dataflow: $name"
    az synapse data-flow create --file @./synapse/workspace/dataflow/"${name}".json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}"
}
createPipeline () {
    declare name=$1
    echo "Creating Synapse Pipeline: $name"
    # Deploy the pipeline
    az synapse pipeline create --file @./synapse/workspace/pipeline/P_Sample3.json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}"
}
createTrigger () {
    declare name=$1
    echo "Creating Synapse Trigger: $name"
    az synapse trigger create --file @./synapse/workspace/trigger/T_Stor.json --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}"
}
startTrigger () {
    declare name=$1
    echo "Starting Synapse Trigger: $name"
    az synapse trigger start --name="${name}" --workspace-name "${SYNAPSE_WORKSPACE_NAME}"
}
writeKeyVaultLSFile () {
    echo "Writing Key Vault Linked Service File locally for deployment"
    keyVaultBaseURL="https://${KEYVAULT_NAME}${KEYVAULT_ENDPOINT}/"

    cp ./synapse/templates/linkedService/Ls_KeyVault_01_template.json ./synapse/workspace/linkedService/Ls_KeyVault_01.json

    echo "Replace Key Vault base url with: $keyVaultBaseURL"
    sed -i "s+<baseurl>+$keyVaultBaseURL+g" \
    ./synapse/workspace/linkedService/Ls_KeyVault_01.json
}
writeDsSqlDWTableFile () {
    echo "Writing SQL DW DataSet File locally for deployment"
    serverName="${SYNAPSE_WORKSPACE_NAME}-WorkspaceDefaultSqlServer"

    cp synapse/templates/dataset/Ds_SqlDW_Table_template.json synapse/workspace/dataset/Ds_SqlDW_Table.json

    echo "Replace SQL DB name with: $SQL_POOL_NAME"
    sed -i "s/<sqldbname>/$SQL_POOL_NAME/g" \
    synapse/workspace/dataset/Ds_SqlDW_Table.json

    echo "Replace Server name with: $serverName"
    sed -i "s/<servername>/$serverName/g" \
    synapse/workspace/dataset/Ds_SqlDW_Table.json
}
writeStorageTriggerFile () {
    echo "Writing Storage Trigger File locally for deployment"
    storageScope=$(az storage account show -g "$RESOURCE_GROUP_NAME" -n "$AZURE_STORAGE_ACCOUNT" --query id -o tsv)

    cp synapse/templates/trigger/T_Stor_template.json synapse/workspace/trigger/T_Stor.json

    echo "Replace Trigger name with: $TRIGGER_NAME"
    sed -i "s/<triggername>/$TRIGGER_NAME/g" \
    synapse/workspace/trigger/T_Stor.json

    echo "Replace Pipeline name with: $PIPELINE_NAME"
    sed -i "s/<pipelinename>/$PIPELINE_NAME/g" \
    synapse/workspace/trigger/T_Stor.json

    echo "Replace Storage scope with: $storageScope"
    sed -i "s+<storagescope>+$storageScope+g" \
    synapse/workspace/trigger/T_Stor.json
}
writepipelineFile () {
    echo "Writing Pipeline File locally for deployment"
    cp synapse/templates/pipeline/P_Sample3_template.json synapse/workspace/pipeline/P_Sample3.json

    echo "Replace Pipeline name with: $PIPELINE_NAME"
    sed -i "s/<pipelinename>/$PIPELINE_NAME/g" \
    synapse/workspace/pipeline/P_Sample3.json
}

# Create the Synapse resources JSON files to prepare for deployment
writeKeyVaultLSFile
writeDsSqlDWTableFile
writeStorageTriggerFile
writepipelineFile

# Deploy all Linked Services
createLinkedService "Ls_KeyVault_01"
createLinkedService "Ls_AdlsGen2_01"

# Deploy all Datasets
createDataset "Ds_AdlsGen2_Data"
createDataset "Ds_Ingest_CSV"
createDataset "Ds_Egress_Parquet"
createDataset "Ds_SqlDW_Table"
createDataset "Ds_AdlsGen2_Interim"

# This line allows the spark pool to be available to attach to the notebooks
az synapse spark session list --workspace-name "${SYNAPSE_WORKSPACE_NAME}" --spark-pool-name "${BIG_DATAPOOL_NAME}"

# Deploy all Notebooks
createNotebook "ETL_sample"

createDataflow "Df_SaveToSQL"

# Deploy all Pipelines
createPipeline $PIPELINE_NAME

# Deploy triggers
createTrigger $TRIGGER_NAME
startTrigger $TRIGGER_NAME

echo "Completed deploying Synapse artifacts."
