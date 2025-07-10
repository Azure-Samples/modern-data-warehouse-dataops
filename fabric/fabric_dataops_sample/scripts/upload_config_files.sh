#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

# Source common functions
. ./scripts/common.sh

# Validate required commands
validate_commands "az" "sed"

# Configuration file paths
config_template_file="./../../config/application.cfg.template"
config_file="./../../config/application.cfg"
lakehouse_ddls_yaml_file="./../../config/lakehouse_ddls.yaml"
seed_dim_date_file="./../../data/seed/dim_date.csv"
seed_dim_time_file="./../../data/seed/dim_time.csv"

# Environment variables
workspace_name="${WORKSPACE_NAME}"
workspace_id="${WORKSPACE_ID}"
lakehouse_name="${LAKEHOUSE_NAME}"
lakehouse_id="${LAKEHOUSE_ID}"
adls_gen2_shortcut_name="${ADLS_GEN2_SHORTCUT_NAME}"
resource_group_name="${RESOURCE_GROUP_NAME}"
keyvault_name="${KEYVAULT_NAME}"
storage_account_name="${STORAGE_ACCOUNT_NAME}"
storage_container_name="${STORAGE_CONTAINER_NAME}"

#######################################################
# Create configuration file from template and parameters
# Arguments:
#   None
# Outputs:
#   Status message about configuration file creation
#######################################################
create_config_file() {
    # Read the config template file and replace the placeholders with the values from the parameters
    sed -e "s/<workspace-name>/${workspace_name}/g" \
        -e "s/<workspace-id>/${workspace_id}/g" \
        -e "s/<lakehouse-name>/${lakehouse_name}/g" \
        -e "s/<lakehouse-id>/${lakehouse_id}/g" \
        -e "s/<keyvault-name>/${keyvault_name}/g" \
        -e "s/<adls-shortcut-name>/${adls_gen2_shortcut_name}/g" \
        "${config_template_file}" > "${config_file}"

    log "Configuration file created at '${config_file}'." "success"
}

#######################################################
# Create directories in the storage container
# Arguments:
#   $1: directory_name - Name of the directory to create
# Outputs:
#   Status message about directory creation
#######################################################
create_storage_directory() {
    local directory_name=${1}

    az storage fs directory create \
        --name "${directory_name}" \
        --file-system "${storage_container_name}" \
        --account-name "${storage_account_name}" \
        --auth-mode login \
        --only-show-errors \
        --output none

    log "Created directory '${directory_name}' in container '${storage_container_name}' of storage account '${storage_account_name}'." "success"
}

#######################################################
# Upload file to the storage
# Arguments:
#   $1: source_file - Path to the source file
#   $2: target_filename - Target filename in storage
# Outputs:
#   Status message about file upload
#######################################################
upload_file() {
    local source_file=${1}
    local target_filename=${2}

    az storage fs file upload \
        --source "${source_file}" \
        --path "${target_filename}" \
        --file-system "${storage_container_name}" \
        --account-name "${storage_account_name}" \
        --auth-mode login \
        --overwrite true \
        --only-show-errors \
        --output none

    log "Uploaded file '${target_filename}' to storage account '${storage_account_name}'." "success"
}

# Main execution flow
log "Creating 'application.cfg' file." "info"
create_config_file

log "Creating directories in the storage container." "info"
create_storage_directory "/config"
create_storage_directory "/reference"

log "Uploading configuration files to storage account." "info"
upload_file "${config_file}" "/config/application.cfg"
upload_file "${lakehouse_ddls_yaml_file}" "/config/lakehouse_ddls.yaml"
upload_file "${seed_dim_date_file}" "/reference/dim_date.csv"
upload_file "${seed_dim_time_file}" "/reference/dim_time.csv"

log "Configuration files upload completed successfully." "success"
