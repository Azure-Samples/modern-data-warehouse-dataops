#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

# Source common functions (adjust path as needed)
. ../../scripts/common.sh

# Validate required commands
validate_commands "curl" "jq" "sed"

# Configuration file paths
config_template_file="config/application.cfg.template"
config_file="config/application.cfg"

#######################################################
# Get workspace ID for a given workspace name
# Arguments:
#   $1: access_token - Fabric access token
#   $2: workspace_name - Name of the workspace
# Outputs:
#   Sets FABRIC_WORKSPACE_ID environment variable
#   Prints workspace ID
# Returns:
#   0 if workspace found, 1 if not found
#######################################################
get_workspace_id() {
    local access_token=${1}
    local workspace_name=${2}

    log "Get workspace ID for ${workspace_name}" "info"

    local url="https://api.fabric.microsoft.com/v1/workspaces"
    local response=$(curl --silent --header "Authorization: Bearer ${access_token}" "${url}")

    log "Workspaces: ${response}" "debug"

    local workspace_id=$(echo "${response}" | jq --raw-output \
        --arg workspace_name "${workspace_name}" \
        '.value[] | select(.displayName == $workspace_name) | .id')

    if [[ -z "${workspace_id}" || "${workspace_id}" == "null" ]]; then
        log "Workspace ${workspace_name} not found." "error"
        return 1
    fi

    export FABRIC_WORKSPACE_ID="${workspace_id}"
    log "Workspace ID: ${workspace_id}" "success"
    return 0
}

#######################################################
# Get lakehouse ID for a given lakehouse name in a workspace
# Arguments:
#   $1: access_token - Fabric access token
#   $2: workspace_id - ID of the workspace
#   $3: lakehouse_name - Name of the lakehouse
# Outputs:
#   Sets FABRIC_LAKEHOUSE_ID environment variable
#   Prints lakehouse ID
# Returns:
#   0 if lakehouse found, 1 if not found
#######################################################
get_lakehouse_id() {
    local access_token=${1}
    local workspace_id=${2}
    local lakehouse_name=${3}

    local url="https://api.fabric.microsoft.com/v1/workspaces/${workspace_id}/items"
    local response=$(curl --silent --header "Authorization: Bearer ${access_token}" "${url}")

    local lakehouse_id=$(echo "${response}" | jq --raw-output \
        --arg lakehouse_name "${lakehouse_name}" \
        '.value[] | select(.displayName == $lakehouse_name and .type == "Lakehouse") | .id')

    if [[ -z "${lakehouse_id}" || "${lakehouse_id}" == "null" ]]; then
        log "Lakehouse ${lakehouse_name} not found." "error"
        return 1
    fi

    export FABRIC_LAKEHOUSE_ID="${lakehouse_id}"
    log "Lakehouse ID: ${lakehouse_id}" "success"
    return 0
}

# Create a configuration file from the template file
function create_config_file() {
    workspace_name=$1
    workspace_id=$2
    lakehouse_name=$3
    lakehouse_id=$4
    keyvault_name=$5
    adls_shortcut_name=$6
    config_file=$7

    echo "Create configuration to config/application.cfg."

    # Read the config template file config/application.cfg.template and replace the placeholders with the actual values
    sed -e "s/<workspace-name>/$workspace_name/g" \
        -e "s/<workspace-id>/$workspace_id/g" \
        -e "s/<lakehouse-name>/$lakehouse_name/g" \
        -e "s/<lakehouse-id>/$lakehouse_id/g" \
        -e "s/<keyvault-name>/$keyvault_name/g" \
        -e "s/<adls-shortcut-name>/$adls_shortcut_name/g" \
        $config_template_file > $config_file

    echo "Configuration file created at $config_file."
}

get_workspace_id \
    "$FABRIC_BEARER_TOKEN"  \
    "$FABRIC_WORKSPACE_NAME" || { echo "Failed to get workspace_id"; exit 1; }

get_lakehouse_id  \
    "$FABRIC_BEARER_TOKEN" \
    "$FABRIC_WORKSPACE_ID" \
    "$FABRIC_LAKEHOUSE_NAME" || { echo "Failed to get lakehouse_id"; exit 1; }

create_config_file \
    "$FABRIC_WORKSPACE_NAME" \
    "$FABRIC_WORKSPACE_ID" \
    "$FABRIC_LAKEHOUSE_NAME" \
    "$FABRIC_LAKEHOUSE_ID" \
    "$KEY_VAULT_NAME" \
    "$FABRIC_ADLS_SHORTCUT_NAME" \
    "$config_file"

mkdir -p adls/config/
cp config/application.cfg adls/config/
cp config/lakehouse_ddls.yaml adls/config/

mkdir -p adls/reference/
cp -r data/seed/* adls/reference
