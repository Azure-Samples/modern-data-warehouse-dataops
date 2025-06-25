
#!/bin/bash

#######################################################
# Deploys Azure DevOps Variable Groups
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
# - Correct Azure DevOps Project selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset

deploy_azdo_variables() {
    log "Deploying Azure DevOps Variables" "info"
    databricks_host=$(get_keyvault_value "databricksDomain" "${kv_name}")
    databricks_kv_token=$(get_keyvault_value "databricksToken" "${kv_name}")
    databricks_workspace_resource_id=$(get_keyvault_value "databricksWorkspaceResourceId" "${kv_name}")
    kv_url=$(get_keyvault_value "kvUrl" "${kv_name}")
    databricksClusterId=$(get_keyvault_value "databricksClusterId" "${kv_name}")
    sql_server_name=$(get_keyvault_value "sqlsrvrName" "${kv_name}")
    sql_server_username=$(get_keyvault_value "sqlsrvUsername" "${kv_name}")
    sql_server_password=$(get_keyvault_value "sqlsrvrPassword" "${kv_name}")
    sql_dw_database_name=$(get_keyvault_value "sqlDwDatabaseName" "${kv_name}")
    azure_storage_account=$(get_keyvault_value "datalakeAccountName" "${kv_name}")
    azure_storage_key=$(get_keyvault_value "datalakeKey" "${kv_name}")
    datafactory_id=$(get_keyvault_value "adfId" "${kv_name}")
    datafactory_name=$(get_keyvault_value "adfName" "${kv_name}")
    sp_adf_id=$(get_keyvault_value "spAdfId" "${kv_name}")
    sp_adf_pass=$(get_keyvault_value "spAdfPass" "${kv_name}")
    sp_adf_tenant=$(get_keyvault_value "spAdfTenantId" "${kv_name}")

    # Const
    if [ "${env_name}" == "dev" ]
    then 
        # In DEV, we fix the path to "dev" folder  to simplify as this is manual publish DEV ADF.
        databricksLibPath='/releases/dev/libs'
        databricksNotebookPath='/releases/dev/notebooks'
    else
        databricksLibPath='/releases/$(Build.BuildId)/libs'
        databricksNotebookPath='/releases/$(Build.BuildId)/notebooks'
    fi

    # Create vargroup
    if vargroup_id=$(az pipelines variable-group list --output json | jq -r -e --arg vg_name "$vargroup_name" '.[] | select(.name==$vg_name) | .id'); then
        log "Variable group: $vargroup_name already exists. Deleting..." "info"
        az pipelines variable-group delete --id "$vargroup_id" -y > /dev/null
    fi
    log "Creating variable group: $vargroup_name" "info"
    az pipelines variable-group create \
        --name "$vargroup_name" \
        --authorize "true" \
        --variables \
            azureLocation="$AZURE_LOCATION" \
            rgName="${resource_group_name}" \
            adfName="${datafactory_name}" \
            databricksLibPath="$databricksLibPath" \
            databricksNotebookPath="$databricksNotebookPath" \
            databricksClusterId="$databricksClusterId" \
            apiBaseUrl="${api_base_url}" \
        --output none

    # Create vargroup - for secrets
    if vargroup_secrets_id=$(az pipelines variable-group list --output json | jq -r -e --arg vg_name "$vargroup_secrets_name" '.[] | select(.name==$vg_name) | .id'); then
        log "Variable group: $vargroup_secrets_name already exists. Deleting..." "info"
        az pipelines variable-group delete --id "${vargroup_secrets_id}" -y > /dev/null
    fi
    log "Creating variable group: $vargroup_secrets_name" "info"
    vargroup_secrets_id=$(az pipelines variable-group create \
        --name "$vargroup_secrets_name" \
        --authorize "true" \
        --output tsv \
        --variables foo="bar" \
        --query "id")  # Needs at least one secret

    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "subscriptionId" --value "${AZURE_SUBSCRIPTION_ID}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "kvUrl" --value "${kv_url}"  --output none
    # sql server
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "sqlsrvrName" --value "${sql_server_name}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "sqlsrvrUsername" --value "${sql_server_username}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "sqlsrvrPassword" --value "${sql_server_password}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "sqlDwDatabaseName" --value "${sql_dw_database_name}"  --output none
    # Databricks
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "databricksDomain" --value "${databricks_host}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "databricksToken" --value "${databricks_kv_token}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "databricksWorkspaceResourceId" \
        --value "${databricks_workspace_resource_id}"  --output none
    # Datalake
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "datalakeAccountName" --value "${azure_storage_account}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "datalakeKey" --value "${azure_storage_key}"  --output none
    # Adf
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "spAdfId" --value "${sp_adf_id}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "spAdfPass" --value "${sp_adf_pass}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "spAdfTenantId" --value "${sp_adf_tenant}"  --output none
    az pipelines variable-group variable create --group-id "${vargroup_secrets_id}" \
        --secret "true" --name "adfResourceId" --value "${datafactory_id}"  --output none
        
    # Delete dummy vars
    az pipelines variable-group variable delete --group-id "${vargroup_secrets_id}" --name "foo" -y > /dev/null
}

# if this is run from the scripts directory, get to root folder and run the build_dependencies function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pushd .. > /dev/null
    . ./scripts/common.sh
    . ./scripts/init_environment.sh
    set_deployment_environment "dev"
    deploy_azdo_variables
    popd > /dev/null
else
    . ./scripts/common.sh
fi
