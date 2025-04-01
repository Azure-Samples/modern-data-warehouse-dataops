#!/bin/bash

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

###################
# REQUIRED ENV VARIABLES:
#
# AZURE_SUBSCRIPTION_ID
# RESOURCE_GROUP_NAME
# DATAFACTORY_NAME
# ADF_DIR

. ./scripts/common.sh

create_adf_linked_service () {
    declare name=$1
    log "Creating ADF LinkedService: $name"
    adfLsUrl="${adfFactoryBaseUrl}/linkedservices/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfLsUrl" --body @"${ADF_DIR}"/linkedService/"${name}".json --output none
}
create_adf_dataset () {
    declare name=$1
    log "Creating ADF Dataset: $name"
    adfDsUrl="${adfFactoryBaseUrl}/datasets/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfDsUrl" --body @"${ADF_DIR}"/dataset/"${name}".json --output none
}
create_adf_pipeline () {
    declare name=$1
    log "Creating ADF Pipeline: $name"
    adfPUrl="${adfFactoryBaseUrl}/pipelines/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfPUrl" --body @"${ADF_DIR}"/pipeline/"${name}".json --output none
}
create_adf_trigger () {
    declare name=$1
    log "Creating ADF Trigger: $name"
    adfTUrl="${adfFactoryBaseUrl}/triggers/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfTUrl" --body @"${ADF_DIR}"/trigger/"${name}".json --output none
}

# Consts
apiVersion="2018-06-01"
baseUrl="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}"
adfFactoryBaseUrl="$baseUrl/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DataFactory/factories/${DATAFACTORY_NAME}"

log "Deploying Data Factory artifacts."

# Deploy all Linked Services
create_adf_linked_service "Ls_KeyVault_01"
create_adf_linked_service "Ls_AdlsGen2_01"
create_adf_linked_service "Ls_AzureSQLDW_01"
create_adf_linked_service "Ls_AzureDatabricks_01"
create_adf_linked_service "Ls_Http_DataSimulator"
# Deploy all Datasets
create_adf_dataset "Ds_AdlsGen2_ParkingData"
create_adf_dataset "Ds_Http_Parking_Locations"
create_adf_dataset "Ds_Http_Parking_Sensors"
# Deploy all Pipelines
create_adf_pipeline "P_Ingest_ParkingData"
# Deploy triggers
create_adf_trigger "T_Sched"

log "Completed deploying Data Factory artifacts."
