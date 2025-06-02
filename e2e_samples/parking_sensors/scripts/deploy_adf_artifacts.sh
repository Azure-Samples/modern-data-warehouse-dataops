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

create_adf_linked_service () {
    declare name=$1
    log "Creating ADF LinkedService: $name" "info"
    adfLsUrl="${adfFactoryBaseUrl}/linkedservices/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfLsUrl" --body @"${ADF_DIR}"/linkedService/"${name}".json --output none
}
create_adf_dataset () {
    declare name=$1
    log "Creating ADF Dataset: $name" "info"
    adfDsUrl="${adfFactoryBaseUrl}/datasets/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfDsUrl" --body @"${ADF_DIR}"/dataset/"${name}".json --output none
}
create_adf_pipeline () {
    declare name=$1
    log "Creating ADF Pipeline: $name" "info"
    adfPUrl="${adfFactoryBaseUrl}/pipelines/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfPUrl" --body @"${ADF_DIR}"/pipeline/"${name}".json --output none
}
create_adf_trigger () {
    declare name=$1
    log "Creating ADF Trigger: $name" "info"
    adfTUrl="${adfFactoryBaseUrl}/triggers/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfTUrl" --body @"${ADF_DIR}"/trigger/"${name}".json --output none
}

# Consts

deploy_adf_artifacts() {
    log "Deploying Data Factory artifacts." "info"

    datafactory_name=get_keyvault_value "adfName" ${kv_name}
    if [ $? -ne 0 ]; then
        log "ADF name not found in Key Vault. Exiting." "error"
        exit 1
    fi
    apiVersion="2018-06-01"
    adfBaseUrl="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}"
    adfFactoryBaseUrl="${adfBaseUrl}/resourceGroups/${resource_group_name}/providers/Microsoft.DataFactory/factories/${datafactory_name}"

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

    log "Completed deploying Data Factory artifacts." "success"
}

# if this is run from the scripts directory, get to root folder and run the build_dependencies function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pushd .. > /dev/null
    . ./scripts/common.sh
    . ./scripts/init_environment.sh
    set_deployment_environment "dev"
    deploy_adf_artifacts
    popd > /dev/null
else
    . ./scripts/common.sh
    deploy_adf_artifacts
fi
