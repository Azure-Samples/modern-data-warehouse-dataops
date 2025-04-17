#!/bin/bash

#######################################################
# Deploys all necessary azure resources and stores
# configuration information in an .ENV file
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset


create_resource_group() {
    # Create resource group
    # check if resource group already exists
    resource_group_name="$PROJECT-$DEPLOYMENT_ID-$ENV_NAME-rg"
    resource_group_exists=$(az group exists --name "$resource_group_name")
    
    if [[ $resource_group_exists == true ]]; then
        log "Resource group $resource_group_name already exists. Skipping creation." "info"
        return
    else
        log "Creating resource group: $resource_group_name" "info"
        az group create --name "$resource_group_name" --location "$AZURE_LOCATION" --tags Environment="$ENV_NAME" --output none
        deploy_success "create_resource_group"
    fi
}

check_keyvault_name() {
    kv_name="$PROJECT-kv-$ENV_NAME-$DEPLOYMENT_ID"
    # By default, set all KeyVault permission to deployer
    # Retrieve KeyVault User Id
    kv_owner_object_id=$(az ad signed-in-user show --output json | jq -r '.id')
    kv_owner_name=$(az ad user show --id "$kv_owner_object_id" --output json | jq -r '.userPrincipalName')

    local keyvault_name_exists=$(az keyvault list --resource-group "${resource_group_name}" --query "[?contains(name, '$kv_name')].name" --output tsv)
    if [[ -n $keyvault_name_exists ]]; then
        log "KeyVault with the same name already exists." "info"
        return
    fi

    log "Checking if the KeyVault name $kv_name can be used..." "info"
    kv_list=$(az keyvault list-deleted --output json --query "[?contains(name,'$kv_name')]")

    if [[ $(echo "$kv_list" | jq -r '.[0]') != null ]]; then
        log "Existing Soft-Deleted KeyVault found: $kv_name. This script will try to replace it." "warning"
        kv_purge_protection_enabled=$(echo "$kv_list" | jq -r '.[0].properties.purgeProtectionEnabled') #can be null or true
        kv_purge_scheduled_date=$(echo "$kv_list" | jq -r '.[0].properties.scheduledPurgeDate')
        # If purge protection is enabled and scheduled date is in the future, then we can't create a new KeyVault with the same name
        if [[ $kv_purge_protection_enabled == true && $kv_purge_scheduled_date > $(date -u +"%Y-%m-%dT%H:%M:%SZ") ]]; then
            log "Existing Soft-Deleted KeyVault has Purge Protection enabled. Scheduled Purge Date: $kv_purge_scheduled_date."$'\n'"As it is not possible to proceed, please change your deployment id."$'\n'"Exiting..." "danger"
            exit 1
        else
            # if purge scheduled date is not in the future or purge protection was not enabled, then ask if user wants to purge the keyvault
            read -p "Deleted KeyVault with the same name exists but can be purged. Do you want to purge the existing KeyVault?"$'\n'"Answering YES will mean you WILL NOT BE ABLE TO RECOVER the old KeyVault and its contents. Answer [y/N]: " response

            case "$response" in
                [yY][eE][sS]|[yY])
                az keyvault purge --name "$kv_name" --no-wait
                ;;
                *)
                log "You selected not to purge the existing KeyVault. Please change deployment id. Exiting..." "danger"
                exit 1
                ;;
            esac
        fi
    fi
}

validate_and_deploy_arm_template() {
    local arm_deployed=$(az deployment group list --resource-group "$resource_group_name")
    if [[ -z $arm_deployed ]]; then
        log "No ARM template deployed. Proceeding with validation." "info"
    else
        log "ARM template already deployed. Skipping validation." "info"
        return
    fi

    # Validate arm template
    log "Validating deployment" "info"
    az deployment group validate \
        --resource-group "$resource_group_name" \
        --template-file "./infrastructure/main.bicep" \
        --parameters @"./infrastructure/main.parameters.${ENV_NAME}.json" \
        --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" deployment_id="${DEPLOYMENT_ID}" \
        --parameters sql_server_password="${AZURESQL_SERVER_PASSWORD}" entra_admin_login="${kv_owner_name}" \
        --parameters keyvault_name="${kv_name}" enable_keyvault_soft_delete="${ENABLE_KEYVAULT_SOFT_DELETE}" \
        --parameters enable_keyvault_purge_protection="${ENABLE_KEYVAULT_PURGE_PROTECTION}"\
        --output none

    deploy_arm_template
}

deploy_arm_template() {
    # Deploy arm template
    log "Deploying resources into $resource_group_name" "info"
    arm_output=$(az deployment group create \
        --resource-group "$resource_group_name" \
        --template-file "./infrastructure/main.bicep" \
        --parameters @"./infrastructure/main.parameters.${ENV_NAME}.json" \
        --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" deployment_id="${DEPLOYMENT_ID}" \
        --parameters sql_server_password="${AZURESQL_SERVER_PASSWORD}" entra_admin_login="${kv_owner_name}" \
        --parameters keyvault_name="${kv_name}" enable_keyvault_soft_delete="${ENABLE_KEYVAULT_SOFT_DELETE}" \
        --parameters enable_keyvault_purge_protection="${ENABLE_KEYVAULT_PURGE_PROTECTION}"\
        --output json)

    if [[ -z $arm_output ]]; then
        log "ARM deployment failed." "danger"
        exit 1
    else
        deploy_success ${current_deploy_stage}
    fi
}

store_keyvault_values_for_deployment() {
    log "Retrieving KeyVault information from the deployment." "info"
    # get keyvault name and id from resource group
    kv_name=$(az keyvault list \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}')].name" \
        --output tsv)

    kv_dns_name=https://${kv_name}.vault.azure.net/

    # Store in KeyVault
    az keyvault secret set --vault-name "$kv_name" --name "kvUrl" --value "$kv_dns_name" --output none
    az keyvault secret set --vault-name "$kv_name" --name "subscriptionId" --value "$AZURE_SUBSCRIPTION_ID" --output none
}

deploy_rest_api() {
    appName="${PROJECT}-api-${ENV_NAME}-${DEPLOYMENT_ID}"
    API_BASE_URL="https://$appName.azurewebsites.net"
    # check that zip was deployed to app service
    local zip_file_succeeded=$(az webapp log deployment list --name "${appName}" --resource-group "${resource_group_name}" --query "[].provisioningState" --output tsv)
    if [[ $zip_file_succeeded = "Succeeded" ]]; then
        log "Zip file deployment already succeeded. Skipping deploy." "info"
        return
    fi

    log "Deploying REST API to AppService: $appName" "info"

    az webapp config appsettings set --resource-group "${resource_group_name}" --name "${appName}" --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true --output none
    az webapp deploy --clean true --resource-group "${resource_group_name}" --name "${appName}" --src-path ./data/data-simulator/data-simulator.zip --type zip --async true --output none

    # Restart the webapp to ensure the latest changes are applied
    az webapp stop --resource-group "${resource_group_name}" --name "${appName}" --output none
    az webapp start --resource-group "${resource_group_name}" --name "${appName}" --output none
}

configure_storage_account() {
    # Retrive account and key
    azure_storage_account=$(az storage account list \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}st${ENV_NAME}')].name" \
        --output tsv)

    azure_storage_key=$(az storage account keys list \
        --account-name "${azure_storage_account}" \
        --resource-group "${resource_group_name}" \
        --output json |
        jq -r '.[0].value')

    # Check if storage container already exists
    local constainer_exists=$(az storage container list --account-name ${azure_storage_account} --account-key ${azure_storage_key} --query "[?name=='datalake'].name" --output tsv)
    if [[ -n $constainer_exists ]]; then
        log "Storage container already exists. Skipping creation." "info"
        return
    fi

    log "Configuring Storage Account" "info"
    # Add file system storage account
    storage_file_system=datalake
    log "Creating ADLS Gen2 File system: ${storage_file_system}"
    az storage container create --name "${storage_file_system}" --account-name "${azure_storage_account}" --account-key "${azure_storage_key}" --output none

    log "Creating folders within the file system."
    # Create folders for databricks libs
    az storage fs directory create -n '/sys/databricks/libs' -f "${storage_file_system}" --account-name "${azure_storage_account}" --account-key "${azure_storage_key}" --output none
    # Create folders for SQL external tables
    az storage fs directory create -n '/data/dw/fact_parking' -f "${storage_file_system}" --account-name "${azure_storage_account}" --account-key "${azure_storage_key}" --output none
    az storage fs directory create -n '/data/dw/dim_st_marker' -f "${storage_file_system}" --account-name "${azure_storage_account}" --account-key "${azure_storage_key}" --output none
    az storage fs directory create -n '/data/dw/dim_parking_bay' -f "${storage_file_system}" --account-name "${azure_storage_account}" --account-key "${azure_storage_key}" --output none
    az storage fs directory create -n '/data/dw/dim_location' -f "${storage_file_system}" --account-name "${azure_storage_account}" --account-key "${azure_storage_key}" --output none

    log "Uploading seed data to data/seed"
    az storage blob upload --container-name "${storage_file_system}" --account-name "${azure_storage_account}" --account-key "${azure_storage_key}" \
        --file data/seed/dim_date.csv --name "data/seed/dim_date/dim_date.csv" --overwrite --output none
    az storage blob upload --container-name "${storage_file_system}" --account-name "${azure_storage_account}" --account-key "${azure_storage_key}" \
        --file data/seed/dim_time.csv --name "data/seed/dim_time/dim_time.csv" --overwrite --output none

    # Set Keyvault secrets
    az keyvault secret set --vault-name "$kv_name" --name "datalakeAccountName" --value "${azure_storage_account}" --output none
    az keyvault secret set --vault-name "$kv_name" --name "datalakeKey" --value "${azure_storage_key}" --output none
    az keyvault secret set --vault-name "$kv_name" --name "datalakeurl" --value "https://${azure_storage_account}.dfs.core.windows.net" --output none
}

configure_sql() {
    log "Retrieving SQL Server information from the deployment." "info"

    # get sql server name, username and synapse pool name from resource group
    sql_server_info=$(az sql server list \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}')].{name:name, username:administratorLogin}" \
        --output json)

    # Extract the SQL server name and username
    sql_server_name=$(echo "$sql_server_info" | jq -r '.[0].name')
    sql_server_username=$(echo "$sql_server_info" | jq -r '.[0].username')

    # Get the SQL pool information
    sql_dw_database_name=$(az sql db list \
        --resource-group "${resource_group_name}" \
        --server "${sql_server_name}" \
        --query "[?contains(name, '${PROJECT}')].name" \
        --output tsv)

    # SQL Connection String
    sql_dw_connstr_nocred=$(az sql db show-connection-string --client ado.net \
        --name "${sql_dw_database_name}" --server "${sql_server_name}" --output json |
        jq -r .)
    sql_dw_connstr_uname=${sql_dw_connstr_nocred/<username>/$sql_server_username}
    sql_dw_connstr_uname_pass=${sql_dw_connstr_uname/<password>/$AZURESQL_SERVER_PASSWORD}

    # Store in Keyvault
    az keyvault secret set --vault-name "${kv_name}" --name "sqlsrvrName" --value "${sql_server_name}" --output none
    az keyvault secret set --vault-name "${kv_name}" --name "sqlsrvUsername" --value "${sql_server_username}" --output none
    az keyvault secret set --vault-name "${kv_name}" --name "sqlsrvrPassword" --value "${AZURESQL_SERVER_PASSWORD}" --output none
    az keyvault secret set --vault-name "${kv_name}" --name "sqldwDatabaseName" --value "${sql_dw_database_name}" --output none
    az keyvault secret set --vault-name "${kv_name}" --name "sqldwConnectionString" --value "${sql_dw_connstr_uname_pass}" --output none
}

configure_app_insights() {
    log "Retrieving ApplicationInsights information from the deployment." "info"

    appinsights_info=$(az monitor app-insights component show \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}')].{instrumentationKey:instrumentationKey, connectionString:connectionString}" \
        --output json)

    appinsights_key=$(echo "${appinsights_info}" | jq -r '.[0].instrumentationKey')
    appinsights_connstr=$(echo "${appinsights_info}" | jq -r '.[0].connectionString')
    
    # Store in Keyvault
    az keyvault secret set --vault-name "${kv_name}" --name "applicationInsightsKey" --value "${appinsights_key}" --output none
    az keyvault secret set --vault-name "${kv_name}" --name "applicationInsightsConnectionString" --value "${appinsights_connstr}" --output none
}

configure_databricks_workspace() {
    log "Configuring Databricks Workspace" "info"
    # Note: SP is required because Credential Passthrough does not support ADF (MSI) as of July 2021

    log "Creating Service Principal (SP) for access to ADLS Gen2 used in Databricks mounting" "info"
    azure_storage_account=$(az storage account list \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}st${ENV_NAME}')].name" \
        --output tsv)
    stor_id=$(az storage account show \
        --name "${azure_storage_account}" \
        --resource-group "${resource_group_name}" \
        --output json |
        jq -r '.id')
    sp_stor_name="${PROJECT}-stor-${ENV_NAME}-${DEPLOYMENT_ID}-sp"
    sp_stor_out=$(az ad sp create-for-rbac \
        --role "Storage Blob Data Contributor" \
        --scopes "${stor_id}" \
        --name "${sp_stor_name}" \
        --output json)

        
    # store storage service principal details in Keyvault
    sp_stor_id=$(echo "${sp_stor_out}" | jq -r '.appId')
    sp_stor_pass=$(echo "${sp_stor_out}" | jq -r '.password')
    sp_stor_tenant=$(echo "${sp_stor_out}" | jq -r '.tenant')

    az keyvault secret set --vault-name "$kv_name" --name "spStorName" --value "$sp_stor_name" --output none
    az keyvault secret set --vault-name "$kv_name" --name "spStorId" --value "$sp_stor_id" --output none
    az keyvault secret set --vault-name "$kv_name" --name "spStorPass" --value="$sp_stor_pass" --output none ##=handles hyphen passwords
    az keyvault secret set --vault-name "$kv_name" --name "spStorTenantId" --value "$sp_stor_tenant" --output none

    log "Generate Databricks token" "info"
    # Get Databricks information from the resource group
    databricks_workspace_info=$(az databricks workspace list \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}')].{name:name, workspaceUrl:workspaceUrl, id:id}" \
        --output json)

    databricks_host=https://$(echo "${databricks_workspace_info}" | jq -r '.[0].workspaceUrl')
    databricks_workspace_resource_id=$(echo "${databricks_workspace_info}" | jq -r '.[0].id')
    databricks_aad_token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken --output tsv) # Databricks app global id
    
    databricks_workspace_name="${PROJECT}-dbw-${ENV_NAME}-${DEPLOYMENT_ID}"
    databricks_complete_url="${databricks_host}/aad/auth?has=&Workspace=/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$resource_group_name/providers/Microsoft.Databricks/workspaces/$databricks_workspace_name&WorkspaceResourceGroupUri=/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$$resource_group_name&l=en"

    # # Display the URL
    log "Please visit the following URL and authenticate: $databricks_complete_url" "action"

    # # Prompt the user for Enter after they authenticate
    read -p "Press Enter after you authenticate to the Azure Databricks workspace..."

    # Use Microsoft Entra access token to generate PAT token
    databricks_token=$(DATABRICKS_TOKEN=$databricks_aad_token \
        DATABRICKS_HOST=${databricks_host} \
        bash -c "databricks tokens create --comment 'deployment'" | jq -r .token_value)

    # Save in KeyVault
    az keyvault secret set --vault-name "${kv_name}" --name "databricksDomain" --value "${databricks_host}" --output none
    az keyvault secret set --vault-name "${kv_name}" --name "databricksToken" --value "${databricks_token}" --output none
    az keyvault secret set --vault-name "${kv_name}" --name "databricksWorkspaceResourceId" --value "${databricks_workspace_resource_id}" --output none

    # Setup the release folder
    if [ "$ENV_NAME" == "dev" ]; then
        databricks_release_folder="/releases/${ENV_NAME}"
    else  
        databricks_release_folder="/releases/setup_release"
    fi
    databricks_folder_name_standardize="${databricks_release_folder}/notebooks/02_standardize"
    log "databricks_folder_name_standardize: ${databricks_folder_name_standardize}" "info"
    databricks_folder_name_transform="${databricks_release_folder}/notebooks/03_transform"
    log "databricks_folder_name_transform: ${databricks_folder_name_transform}" "info"
}

configure_unity_catalog() {
    log "Configuring Databricks Unity Catalog" "info"

    ################################################
    # Configure Unity Catalog
    cat_stg_account_name="${PROJECT}catalog${ENV_NAME}${DEPLOYMENT_ID}"
    data_stg_account_name="${PROJECT}st${ENV_NAME}${DEPLOYMENT_ID}"
    resource_group_name="${PROJECT}-${DEPLOYMENT_ID}-${ENV_NAME}-rg"
    mng_resource_group_name="${PROJECT}-${DEPLOYMENT_ID}-dbw-${ENV_NAME}-rg"
    stg_credential_name="${PROJECT}-${DEPLOYMENT_ID}-stg-credential-${ENV_NAME}"
    catalog_ext_location_name="${PROJECT}-catalog-${DEPLOYMENT_ID}-ext-location-${ENV_NAME}"
    data_ext_location_name="${PROJECT}-data-${DEPLOYMENT_ID}-ext-location-${ENV_NAME}"
    catalog_name="${PROJECT}-${DEPLOYMENT_ID}-catalog-${ENV_NAME}"

    SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID} \
    DATABRICKS_KV_TOKEN=${databricks_token} \
    DATABRICKS_HOST=${databricks_host} \
    ENVIRONMENT_NAME=${ENV_NAME} \
    AZURE_LOCATION=${AZURE_LOCATION} \
    CATALOG_STG_ACCOUNT_NAME=${cat_stg_account_name} \
    DATA_STG_ACCOUNT_NAME=${data_stg_account_name} \
    RESOURCE_GROUP_NAME=${resource_group_name} \
    MNG_RESOURCE_GROUP_NAME=${mng_resource_group_name} \
    STG_CREDENTIAL_NAME=${stg_credential_name} \
    CATALOG_EXT_LOCATION_NAME=${catalog_ext_location_name} \
    DATA_EXT_LOCATION_NAME=${data_ext_location_name} \
    CATALOG_NAME=${catalog_name} \
        bash -c "./scripts/configure_unity_catalog.sh"
}

configure_databricks_cluster() {
    log "Configuring Databricks Cluster" "info"

    keyvault_resource_id=$(az keyvault show \
        --name "${kv_name}" \
        --query "id" \
        --output tsv)

    # Configure databricks (KeyVault-backed Secret scope, mount to storage via SP, databricks tables, cluster)
    # NOTE: must use Microsoft Entra access token, not PAT token
    AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID} \
    RESOURCE_GROUP_NAME=${resource_group_name} \
    STORAGE_ACCOUNT_NAME=${azure_storage_account} \
    ENVIRONMENT_NAME=${ENV_NAME} \
    PROJECT=${PROJECT} \
    DEPLOYMENT_ID=${DEPLOYMENT_ID} \
    DATABRICKS_TOKEN=${databricks_aad_token} \
    DATABRICKS_KV_TOKEN=${databricks_token} \
    DATABRICKS_HOST=${databricks_host} \
    KEYVAULT_DNS_NAME=${kv_dns_name} \
    KEYVAULT_NAME=${kv_name} \
    USER_NAME=${kv_owner_name} \
    AZURE_LOCATION=${AZURE_LOCATION} \
    DATABRICKS_RELEASE_FOLDER=${databricks_release_folder} \
    KEYVAULT_RESOURCE_ID=${keyvault_resource_id} \
        bash -c "./scripts/configure_databricks.sh"
}

configure_datafactory() {
    log "Configuring Data Factory" "info"

    # Get Databricks ClusterID from KeyVault
    databricksClusterId=$(az keyvault secret show --name "databricksClusterId" --vault-name "$kv_name" --query "value" --output tsv)

    log "Updating Data Factory LinkedService to point to newly deployed resources (KeyVault and DataLake)."
    # Create a copy of the ADF dir into a .tmp/ folder.
    adfTempDir=.tmp/adf
    mkdir -p $adfTempDir && cp -a adf/ .tmp/
    # Update ADF LinkedServices to point to newly deployed Datalake URL, KeyVault URL, and Databricks workspace URL
    tmpfile=.tmpfile
    adfLsDir=$adfTempDir/linkedService
    adfPlDir=$adfTempDir/pipeline
    catalog_name="${PROJECT}-${DEPLOYMENT_ID}-catalog-${ENV_NAME}"
    jq --arg kvurl "$kv_dns_name" '.properties.typeProperties.baseUrl = $kvurl' $adfLsDir/Ls_KeyVault_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_KeyVault_01.json
    jq --arg databricksWorkspaceUrl "$databricks_host" '.properties.typeProperties.domain = $databricksWorkspaceUrl' $adfLsDir/Ls_AzureDatabricks_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_AzureDatabricks_01.json
    jq --arg databricksExistingClusterId "$databricksClusterId" '.properties.typeProperties.existingClusterId = $databricksExistingClusterId' $adfLsDir/Ls_AzureDatabricks_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_AzureDatabricks_01.json
    jq --arg datalakeUrl "https://${azure_storage_account}.dfs.core.windows.net" '.properties.typeProperties.url = $datalakeUrl' $adfLsDir/Ls_AdlsGen2_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_AdlsGen2_01.json
    jq --arg databricks_folder_name_standardize "$databricks_folder_name_standardize" '.properties.activities[0].typeProperties.notebookPath = $databricks_folder_name_standardize' $adfPlDir/P_Ingest_ParkingData.json > "$tmpfile" && mv "$tmpfile" $adfPlDir/P_Ingest_ParkingData.json
    jq --arg databricks_folder_name_transform  "$databricks_folder_name_transform" '.properties.activities[4].typeProperties.notebookPath = $databricks_folder_name_transform' $adfPlDir/P_Ingest_ParkingData.json > "$tmpfile" && mv "$tmpfile" $adfPlDir/P_Ingest_ParkingData.json
    jq --arg notebook_base_param_catalog_name "$catalog_name" '.properties.activities[0].typeProperties.baseParameters.catalogname.value = $notebook_base_param_catalog_name' $adfPlDir/P_Ingest_ParkingData.json > "$tmpfile" && mv "$tmpfile" $adfPlDir/P_Ingest_ParkingData.json
    jq --arg notebook_base_param_stg_account_name "${azure_storage_account}" '.properties.activities[0].typeProperties.baseParameters.stgaccountname.value = $notebook_base_param_stg_account_name' $adfPlDir/P_Ingest_ParkingData.json > "$tmpfile" && mv "$tmpfile" $adfPlDir/P_Ingest_ParkingData.json
    jq --arg notebook_base_param_catalog_name "$catalog_name" '.properties.activities[4].typeProperties.baseParameters.catalogname.value = $notebook_base_param_catalog_name' $adfPlDir/P_Ingest_ParkingData.json > "$tmpfile" && mv "$tmpfile" $adfPlDir/P_Ingest_ParkingData.json
    jq --arg notebook_base_param_stg_account_name "${azure_storage_account}" '.properties.activities[4].typeProperties.baseParameters.stgaccountname.value = $notebook_base_param_stg_account_name' $adfPlDir/P_Ingest_ParkingData.json > "$tmpfile" && mv "$tmpfile" $adfPlDir/P_Ingest_ParkingData.json
    jq --arg new_url "$API_BASE_URL" '.properties.typeProperties.url = $new_url' "$adfLsDir/Ls_Http_DataSimulator.json" > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_Http_DataSimulator.json
    jq --arg new_url "$API_BASE_URL" '.properties.typeProperties.url = $new_url' $adfLsDir/Ls_Rest_ParkSensors_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_Rest_ParkSensors_01.json

    datafactory_info=$(az datafactory list \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}')].{name:name, id:id}" \
        --output json)

    # Extract Data Factory name and ID
    datafactory_name=$(echo "$datafactory_info" | jq -r '.[0].name')
    datafactory_id=$(echo "$datafactory_info" | jq -r '.[0].id')
    az keyvault secret set --vault-name "$kv_name" --name "adfName" --value "$datafactory_name" --output none

    log "Modified sample files saved to directory: $adfTempDir"
    # Deploy ADF artifacts
    AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
    RESOURCE_GROUP_NAME=$resource_group_name \
    DATAFACTORY_NAME=$datafactory_name \
    ADF_DIR=$adfTempDir \
        bash -c "./scripts/deploy_adf_artifacts.sh"

    # ADF SP for integration tests
    log "Create Service Principal (SP) for Data Factory"
    sp_adf_name="${PROJECT}-adf-${ENV_NAME}-${DEPLOYMENT_ID}-sp"
    sp_adf_out=$(az ad sp create-for-rbac \
        --role "Data Factory contributor" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$resource_group_name/providers/Microsoft.DataFactory/factories/$datafactory_name" \
        --name "$sp_adf_name" \
        --output json)
    
    sp_adf_id=$(echo "$sp_adf_out" | jq -r '.appId')
    sp_adf_pass=$(echo "$sp_adf_out" | jq -r '.password')
    sp_adf_tenant=$(echo "$sp_adf_out" | jq -r '.tenant')

    # Save ADF SP credentials in Keyvault
    az keyvault secret set --vault-name "$kv_name" --name "spAdfName" --value "$sp_adf_name" --output none
    az keyvault secret set --vault-name "$kv_name" --name "spAdfId" --value "$sp_adf_id" --output none
    az keyvault secret set --vault-name "$kv_name" --name "spAdfPass" --value="$sp_adf_pass" --output none ##=handles hyphen passwords
    az keyvault secret set --vault-name "$kv_name" --name "spAdfTenantId" --value "$sp_adf_tenant" --output none
}

configure_azdo_service_connections_and_variables() {
    log "Configuring Azure DevOps Service Connections and Variables" "info"

    ####################
    # AZDO Azure Service Connection and Variables Groups

    # AzDO Azure Service Connections
    PROJECT=${PROJECT} \
    ENV_NAME=${ENV_NAME} \
    RESOURCE_GROUP_NAME=${resource_group_name} \
    DEPLOYMENT_ID=${DEPLOYMENT_ID} \
    TENANT_ID=${TENANT_ID} \
    AZDO_PROJECT=${AZDO_PROJECT} \
    AZDO_ORGANIZATION_URL=${AZDO_ORGANIZATION_URL} \
        bash -c "./scripts/deploy_azdo_service_connections_azure.sh"

    # AzDO Variable Groups
    PROJECT=${PROJECT} \
    ENV_NAME=${ENV_NAME} \
    AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID} \
    RESOURCE_GROUP_NAME=${resource_group_name} \
    AZURE_LOCATION=${AZURE_LOCATION} \
    KV_URL=${kv_dns_name} \
    KV_NAME=${kv_name} \
    DATABRICKS_TOKEN=${databricks_token} \
    DATABRICKS_HOST=${databricks_host} \
    DATABRICKS_WORKSPACE_RESOURCE_ID=${databricks_workspace_resource_id} \
    DATABRICKS_CLUSTER_ID=${databricksClusterId} \
    SQL_SERVER_NAME=${sql_server_name} \
    SQL_SERVER_USERNAME=${sql_server_username} \
    SQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD} \
    SQL_DW_DATABASE_NAME=${sql_dw_database_name} \
    AZURE_STORAGE_KEY=${azure_storage_key} \
    AZURE_STORAGE_ACCOUNT=${azure_storage_account} \
    DATAFACTORY_ID=${datafactory_id} \
    DATAFACTORY_NAME=${datafactory_name} \
    SP_ADF_ID=${sp_adf_id} \
    SP_ADF_PASS=${sp_adf_pass} \
    SP_ADF_TENANT=${sp_adf_tenant} \
    API_BASE_URL=${API_BASE_URL} \
        bash -c "./scripts/deploy_azdo_variables.sh"
}

write_deployment_environment_variables() {
    log "Writing deployment environment variables" "info"

    env_file=".env.${ENV_NAME}"
    log "Appending configuration to .env file." "info"
    cat << EOF >> "${env_file}"

# ------ Configuration from deployment on $(date "+%Y-%m-%d %H:%M:%S %Z") -----------
RESOURCE_GROUP_NAME=${resource_group_name}
AZURE_LOCATION=${AZURE_LOCATION}
SQL_SERVER_NAME=${sql_server_name}
SQL_SERVER_USERNAME=${sql_server_username}
SQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD}
SQL_DW_DATABASE_NAME=${sql_dw_database_name}
AZURE_STORAGE_ACCOUNT=${azure_storage_account}
AZURE_STORAGE_KEY=${azure_storage_key}
SP_STOR_NAME=${sp_stor_name}
SP_STOR_ID=${sp_stor_id}
SP_STOR_PASS=${sp_stor_pass}
SP_STOR_TENANT=${sp_stor_tenant}
DATABRICKS_HOST=${databricks_host}
DATABRICKS_TOKEN=${databricks_token}
DATAFACTORY_NAME=${datafactory_name}
APPINSIGHTS_KEY=${appinsights_key}
KV_URL=${kv_dns_name}

EOF
    log "Completed deploying Azure resources ${resource_group_name} ($ENV_NAME)" "success"
}

deploy_infrastructure() {
    log "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID" "info"

    create_resource_group
    check_keyvault_name
    validate_and_deploy_arm_template
    store_keyvault_values_for_deployment
    deploy_rest_api
    configure_storage_account
    configure_sql
    configure_app_insights
    configure_databricks_workspace
    configure_unity_catalog
    configure_databricks_cluster
    configure_datafactory
    configure_azdo_service_connections_and_variables
    write_deployment_environment_variables
}

deploy_infrastructure_environment() {
    ##function to allow user deploy enviromnents
    ## 1) Only Dev
    ## 2) Dev and Stage
    ## 3)  Dev, Stage and Prod
    ##Default  is option 3.
    ENV_DEPLOY=${1:-3}
    case ${ENV_DEPLOY} in
    1)
        log "Deploying Dev Environment only..." "info"
        env_names="dev"
        ;;
    2)    
        log "Deploying Dev and Stage Environments..." "info"
        env_names="dev stg"
        ;;
    3) 
        log "Full Deploy: Dev, Stage and Prod Environments..." "info"
        env_names="dev stg prod"
        ;;
    *)
        log "Invalid choice. Exiting..." "error"
        exit
        ;;
    esac

    # Loop through the environments and deploy
    for env_name in ${env_names}; do
        echo "Currently deploying to the environment: ${env_name}"
        export ENV_NAME=${env_name}
        deploy_infrastructure || {
            log "Deployment failed for ${env_name}" "error"
            exit 1
        }
        export ENV_DEPLOY=${ENV_DEPLOY}
    done
}

# if this is run from the scripts directory, get to root folder and run the build_dependencies function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pushd .. > /dev/null

    . ./scripts/common.sh
    . ./scripts/init_environment.sh
    log "Deploying Infrastructure..." "info"
    deploy_infrastructure_environment 1 "${PROJECT}"

    popd > /dev/null
else
    . ./scripts/common.sh
fi
