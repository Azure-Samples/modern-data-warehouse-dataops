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

set -o errexit
set -o pipefail
set -o nounset

# REQUIRED VARIABLES:
# SUBSCRIPTION_ID
# DATABRICKS_HOST
# DATABRICKS_KV_TOKEN
# ENVIRONMENT_NAME
# AZURE_LOCATION
# CATALOG_STG_ACCOUNT_NAME
# DATA_STG_ACCOUNT_NAME
# RESOURCE_GROUP_NAME
# MNG_RESOURCE_GROUP_NAME
# STG_CREDENTIAL_NAME
# CATALOG_EXT_LOCATION_NAME
# DATA_EXT_LOCATION_NAME
# CATALOG_NAME

get_databricks_host () {
  resource_group_name=$1
  databricks_workspace_info=$(az databricks workspace list \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}')].{name:name, workspaceUrl:workspaceUrl, id:id}" \
        --output json)
  echo https://$(echo "${databricks_workspace_info}" | jq -r '.[0].workspaceUrl')
}

create_db_external_location(){
    declare json_ext_location=$1
    declare external_location_name=$2

    # Check if the external location already exists
    log "External Location Name: $external_location_name" "info"

    if [ -n "$external_location_name" ]; then
      if [ -z "$(databricks external-locations list | grep -w $external_location_name)" ]; then
          log "External location '$external_location_name' does not exist. Creating it now..." "info"
          databricks external-locations create --json @$json_ext_location
          log "External location '$external_location_name' created successfully."
      else
          log "External location '$external_location_name' already exists. Skipping creation." "info"
      fi
    else
      log "External location name is empty. Skipping creation." "info"
    fi
}

create_db_catalog(){
    declare json_uc=$1
    declare catalog_name=$2

    log "Catalog Name: $catalog_name" "info"
    # Check if the catalog already exists
    if [ -n "$catalog_name" ]; then
      if [ -z "$(databricks catalogs list | grep -w "$catalog_name")" ]; then
          log "Catalog '$catalog_name' does not exist. Creating it now..." "info"
          databricks catalogs create --json @$json_uc
          log "Catalog '$catalog_name' created successfully."
      else
          log "Catalog '$catalog_name' already exists. Skipping creation." "info"
      fi
    else
      log "Catalog name is empty. Skipping creation." "info"
    fi
}

assign_rbac_role_to_msi(){
    declare role=${1}
    declare scope=${2}
    declare managed_identity_principal_id=${3}
    declare stg_account_name=${4}

    # Assign the role to the managed identity
    az role assignment create --assignee "${managed_identity_principal_id}" --role "${role}" --scope "${scope}" --output none
    log "Role '${role}' assigned to managed identity '${managed_identity_name}' for storage account '${stg_account_name}'." "info"
}

create_catalog_storage_account() {
  # Check if the catalog storage account already exists
  name_available=$(az storage account check-name --name ${cat_stg_account_name} --query "nameAvailable" --output tsv)
  
  if [ "${name_available}" == "true" ]; then
    log "Storage account '${cat_stg_account_name}' does not exist. Creating it now..."
    az storage account create \
      --name ${cat_stg_account_name} \
      --resource-group ${resource_group_name} \
      --location ${AZURE_LOCATION} \
      --sku Standard_LRS \
      --kind StorageV2 \
      --hns true
    log "Storage account '${cat_stg_account_name}' created successfully with hierarchical namespace enabled." "info"
  else
    log "Storage account '${cat_stg_account_name}' already exists. Skipping creation." "info"
  fi
}

create_catalog_storage_container() {
  # Check if the container already exists
  container_exists=$(az storage container exists --name ${env_name} --account-name ${cat_stg_account_name} --auth-mode login --query "exists" --output tsv)

  if [ "${container_exists}" == "false" ]; then
    log "Container '${env_name}' does not exist. Creating it now..." "info"
    az storage container create \
      --name ${env_name} \
      --account-name ${cat_stg_account_name} \
      --auth-mode login \
      --output none
    log "Container '${env_name}' created successfully in storage account '${cat_stg_account_name}'." "info"
  else
    log "Container '${env_name}' already exists. Skipping creation." "info"
  fi
}

create_storage_credential() {
  json_storage_credential="./databricks/config/storage.credential.json"
  # Create the JSON file
  cat <<EOF > ${json_storage_credential}
{
  "name": "${stg_credential_name}",
  "azure_managed_identity": {
    "access_connector_id": "/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${mng_resource_group_name}/providers/Microsoft.Databricks/accessConnectors/unity-catalog-access-connector"
  }
}
EOF

  # Check if the storage credential already exists
  if [ -n "${stg_credential_name}" ]; then
    if [ -z "$(databricks storage-credentials list | grep -w ${stg_credential_name})" ]; then
      log "Storage credential '${stg_credential_name}' does not exist. Creating it now..."
      databricks storage-credentials create --json @$json_storage_credential
      log "Storage credential '${stg_credential_name}' created successfully." "info"
    else
      log "Storage credential '${stg_credential_name}' already exists. Skipping creation." "info"
    fi
  else
    log "Storage credential name is empty. Skipping creation." "info"
  fi
}

rbac_role_assignment_for_msi() {
  # RBAC role assignment to the MSI for the storage account that holds the catalog
  scope="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${resource_group_name}/providers/Microsoft.Storage/storageAccounts/${cat_stg_account_name}"
  access_connector_resource_id="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${mng_resource_group_name}/providers/Microsoft.Databricks/accessConnectors/unity-catalog-access-connector"

  # Get the name of the MSI using the resource ID
  managed_identity_name=$(az resource show --ids ${access_connector_resource_id} --query 'name' --output tsv)
  log "Managed Identity Name: ${managed_identity_name}" "info"
  # Get the managed identity principal ID
  managed_identity_principal_id=$(az resource show --ids ${access_connector_resource_id} --query 'identity.principalId' --output tsv)   
  log "Managed Identity Principal ID: ${managed_identity_principal_id}" "info"
  # Assign the role to the managed identity
  role="Storage Blob Data Contributor"
  assign_rbac_role_to_msi "${role}" "${scope}" "${managed_identity_principal_id}" "${cat_stg_account_name}"

  # Assign the role to the managed identity
  scope="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${resource_group_name}/providers/Microsoft.Storage/storageAccounts/${data_stg_account_name}"
  # Assign the role to the managed identity
  role="Storage Blob Data Contributor"
  assign_rbac_role_to_msi "${role}" "${scope}" "${managed_identity_principal_id}" "${data_stg_account_name}" "info"	

  # Wait for the RBAC role assignment to propagate
  sleep 60
}

create_external_locations() {
  # Create the external location for the catalog
  cat_json_ext_location="./databricks/config/catalog.external.location.json"
  # Create the JSON file
  cat <<EOF > ${cat_json_ext_location}
{
  "name": "${catalog_ext_location_name}",
  "url": "abfss://${env_name}@${cat_stg_account_name}.dfs.core.windows.net",
  "credential_name": "${stg_credential_name}"
}
EOF
  
  create_db_external_location ${cat_json_ext_location} ${catalog_ext_location_name}

  data_json_ext_location="./databricks/config/data.external.location.json"
  # Create the JSON file
  cat <<EOF > ${data_json_ext_location}
{
  "name": "${data_ext_location_name}",
  "url": "abfss://datalake@${data_stg_account_name}.dfs.core.windows.net",
  "credential_name": "${stg_credential_name}"
}
EOF

  create_db_external_location $data_json_ext_location ${data_ext_location_name}
}

create_environment_catalog() {
  comment="Catalog for ${env_name} environment."

  json_uc="./databricks/config/uc.json"
  # Create the JSON file
  cat <<EOF > ${json_uc}
{
  "name": "${env_name}",
  "comment": "${comment}",
  "storage_root": "abfss://${env_name}@$cat_stg_account_name.dfs.core.windows.net"
}
EOF

  create_db_catalog $json_uc $env_name
}

configure_unity_catalog() {
  env_deploy=${1:-3}

  get_env_names "${env_deploy}"
  # Loop through the environments and deploy
  for env_name in ${env_names}; do
    set_deployment_environment "${env_name}"
  
    # Create the databrickscfg file
    databricks_host=$(get_databricks_host ${resource_group_name})
    if [ -z "$databricks_host" ]; then
      log "Databricks host is empty. Exiting." "Error"
      exit 1
    fi
    #get databricks token from key vault
    databricks_kv_token=$(az keyvault secret show --name databricksToken --vault-name $kv_name --query value -o tsv)
    if [ -z "${databricks_kv_token}" ]; then
      log "Databricks token is empty. Exiting." "Error"
      exit 1
    fi
    cat <<EOL > ~/.databrickscfg
[DEFAULT]
host=${databricks_host}
token=${databricks_kv_token}
EOL

    log "Creating and configuring Unity Catalog for ${env_name}." "info"
    create_catalog_storage_account
    create_catalog_storage_container ${env_name}
    create_storage_credential
    rbac_role_assignment_for_msi
    create_external_locations
    create_environment_catalog
    log "Unity Catalog configured successfully." "info"
  done
}


# if this is run from the scripts directory, get to root folder and run the build_dependencies function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pushd .. > /dev/null
    . ./scripts/common.sh
    . ./scripts/init_environment.sh
    configure_unity_catalog 1
    popd > /dev/null
else
    . ./scripts/common.sh
fi
