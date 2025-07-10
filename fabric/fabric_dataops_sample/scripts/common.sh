#!/bin/bash

# Common functions library for Fabric DataOps Sample
# This file provides standardized functions for logging, validation, and common operations

#######################################################
# Color-coded logging function with levels
# Arguments:
#   $1: message - The message to log
#   $2: style - The log level (info, debug, success, error, warning, danger, action)
# Outputs:
#   Colored message to stderr
#######################################################
print_style() {
    case "${2}" in
        "info")
            COLOR="96m"
            ;;
        "debug")
            COLOR="96m"
            ;;
        "success")
            COLOR="92m"
            ;;
        "error")
            COLOR="91m"
            ;;
        "warning")
            COLOR="93m"
            ;;
        "danger")
            COLOR="91m"
            ;;
        "action")
            COLOR="32m"
            ;;
        *)
            COLOR="0m"
            ;;
    esac

    STARTCOLOR="\e[${COLOR}"
    ENDCOLOR="\e[0m"
    printf "${STARTCOLOR}%b${ENDCOLOR}" "${1}"
}

#######################################################
# Main logging function with color support
# Arguments:
#   $1: message - The message to log
#   $2: style - The log level (optional, defaults to no color)
# Outputs:
#   Formatted message to stderr
#######################################################
log() {
    local message=${1}
    local style=${2:-}

    if [[ -z "${style}" ]]; then
        echo -e "$(print_style "${message}" "default")" >&2
    else
        echo -e "$(print_style "${message}" "${style}")" >&2
    fi
}

#######################################################
# Wait function for asynchronous operations
# Arguments:
#   $1: seconds - Number of seconds to wait (defaults to 15)
# Outputs:
#   Info message about waiting
#######################################################
wait_for_process() {
    local seconds=${1:-15}
    log "Giving the portal ${seconds} seconds to process the information..." "info"
    sleep "${seconds}"
}

#######################################################
# Generate random string of specified length
# Arguments:
#   $1: length - Length of the random string
# Outputs:
#   Random string of specified length
#######################################################
random_str() {
    local length=${1}
    cat /dev/urandom | tr --delete-chars 'a-zA-Z0-9' | fold --width="${length}" | head --lines=1 | tr '[:upper:]' '[:lower:]'
    return 0
}

#######################################################
# Check if a command exists
# Arguments:
#   $1: command_name - Name of the command to check
# Returns:
#   0 if command exists, 1 otherwise
#######################################################
command_exists() {
    command -v "${1}" >/dev/null 2>&1
}

#######################################################
# Validate that required commands are available
# Arguments:
#   $@: List of required commands
# Outputs:
#   Error messages for missing commands
# Returns:
#   Exits with 1 if any command is missing
#######################################################
validate_commands() {
    local missing_commands=()
    
    for cmd in "$@"; do
        if ! command_exists "${cmd}"; then
            missing_commands+=("${cmd}")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log "The following required commands are missing:" "error"
        for cmd in "${missing_commands[@]}"; do
            log "  - ${cmd}" "error"
        done
        exit 1
    fi
}

#######################################################
# Validate that required environment variables are set
# Arguments:
#   $@: List of required environment variables
# Outputs:
#   Error messages for missing variables
# Returns:
#   Exits with 1 if any variable is missing
#######################################################
validate_required_vars() {
    local missing_vars=()
    
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("${var}")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log "The following required environment variables are missing:" "error"
        for var in "${missing_vars[@]}"; do
            log "  - ${var}" "error"
        done
        exit 1
    fi
}

#######################################################
# Check if user is logged in to Azure CLI
# Returns:
#   0 if logged in, 1 otherwise
#######################################################
check_azure_login() {
    if az account show >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

#######################################################
# Check if a resource group exists
# Arguments:
#   $1: resource_group_name - Name of the resource group
# Returns:
#   0 if resource group exists, 1 otherwise
#######################################################
resource_group_exists() {
    local resource_group_name=${1}
    az group show --name "${resource_group_name}" >/dev/null 2>&1
    return $?
}

#######################################################
# Get a secret value from Azure Key Vault
# Arguments:
#   $1: secret_name - Name of the secret
#   $2: kv_name - Name of the Key Vault
# Outputs:
#   Secret value
# Returns:
#   Exits with 1 if secret is not found
#######################################################
get_keyvault_value() {
    local secret_name=${1}
    local kv_name=${2}
    local secret_value=$(az keyvault secret show --name "${secret_name}" --vault-name "${kv_name}" --query value --output tsv)
    
    if [[ -z "${secret_value}" ]]; then
        log "Secret ${secret_name} not found in Key Vault ${kv_name}. Exiting." "error"
        exit 1
    fi
    
    echo "${secret_value}"
}

#######################################################
# Get Azure DevOps repository ID by name
# Arguments:
#   $1: repo_name - Name of the repository
# Outputs:
#   Repository ID
#######################################################
get_azdo_repo_id() {
    local repo_name=${1}
    local repo_output=$(az repos list --query "[?name=='${repo_name}']" --output json)
    local repo_id=$(echo "${repo_output}" | jq --raw-output '.[0].id')
    echo "${repo_id}"
}

#######################################################
# Get Azure DevOps pipeline ID by name
# Arguments:
#   $1: pipeline_name - Name of the pipeline
# Outputs:
#   Pipeline ID
#######################################################
get_azdo_pipeline_id() {
    local pipeline_name=${1}
    local pipeline_output=$(az pipelines list --query "[?name=='${pipeline_name}']" --output json)
    local pipeline_id=$(echo "${pipeline_output}" | jq --raw-output '.[0].id')
    echo "${pipeline_id}"
}

#######################################################
# Get security group ID by name
# Arguments:
#   $1: security_group_name - Name of the security group
# Outputs:
#   Security group ID
#######################################################
get_security_group_id() {
    local security_group_name=${1}
    local security_group_id=$(az ad group show --group "${security_group_name}" --query id --output tsv)
    echo "${security_group_id}"
}

#######################################################
# Check if a file exists and is readable
# Arguments:
#   $1: file_path - Path to the file
# Returns:
#   0 if file exists and is readable, 1 otherwise
#######################################################
file_exists() {
    local file_path=${1}
    [[ -f "${file_path}" && -r "${file_path}" ]]
}

#######################################################
# Replace text in file (cross-platform)
# Arguments:
#   $1: search_text - Text to search for
#   $2: replace_text - Text to replace with
#   $3: file_path - Path to the file
#######################################################
replace_in_file() {
    local search_text=${1}
    local replace_text=${2}
    local file_path=${3}
    
    if [[ "${OSTYPE}" == "darwin"* ]]; then
        sed -i '' "s/${search_text}/${replace_text}/g" "${file_path}"
    else
        sed -i "s/${search_text}/${replace_text}/g" "${file_path}"
    fi
}

#######################################################
# Wait for Azure deployment to complete
# Arguments:
#   $1: resource_group_name - Name of the resource group
#   $2: deployment_name - Name of the deployment
# Outputs:
#   Status messages about deployment progress
#######################################################
wait_for_deployment() {
    local resource_group_name=${1}
    local deployment_name=${2}
    
    log "Waiting for deployment '${deployment_name}' in resource group '${resource_group_name}' to complete..." "info"
    
    az deployment group wait \
        --resource-group "${resource_group_name}" \
        --name "${deployment_name}" \
        --created \
        --timeout 3600
    
    log "Deployment '${deployment_name}' completed successfully." "success"
}

#######################################################
# Check if a Key Vault exists
# Arguments:
#   $1: kv_name - Name of the Key Vault
# Returns:
#   0 if Key Vault exists, 1 otherwise
#######################################################
keyvault_exists() {
    local kv_name=${1}
    az keyvault show --name "${kv_name}" >/dev/null 2>&1
    return $?
}

#######################################################
# Get Fabric workspace ID by name
# Arguments:
#   $1: access_token - Fabric access token
#   $2: workspace_name - Name of the workspace
# Outputs:
#   Workspace ID
# Returns:
#   1 if workspace not found
#######################################################
get_fabric_workspace_id() {
    local access_token=${1}
    local workspace_name=${2}
    
    log "Getting workspace ID for ${workspace_name}" "info"
    
    local url="https://api.fabric.microsoft.com/v1/workspaces"
    local response=$(curl --silent --header "Authorization: Bearer ${access_token}" "${url}")
    
    log "Workspaces response: ${response}" "debug"
    
    local workspace_id=$(echo "${response}" | jq --raw-output --arg workspace_name "${workspace_name}" '.value[] | select(.displayName == $workspace_name) | .id')
    
    if [[ -z "${workspace_id}" || "${workspace_id}" == "null" ]]; then
        log "Workspace ${workspace_name} not found." "error"
        return 1
    fi
    
    echo "${workspace_id}"
    return 0
}

#######################################################
# Get Fabric lakehouse ID by name
# Arguments:
#   $1: access_token - Fabric access token
#   $2: workspace_id - ID of the workspace
#   $3: lakehouse_name - Name of the lakehouse
# Outputs:
#   Lakehouse ID
# Returns:
#   1 if lakehouse not found
#######################################################
get_fabric_lakehouse_id() {
    local access_token=${1}
    local workspace_id=${2}
    local lakehouse_name=${3}
    
    local url="https://api.fabric.microsoft.com/v1/workspaces/${workspace_id}/items"
    local response=$(curl --silent --header "Authorization: Bearer ${access_token}" "${url}")
    
    local lakehouse_id=$(echo "${response}" | jq --raw-output --arg lakehouse_name "${lakehouse_name}" '.value[] | select(.displayName == $lakehouse_name and .type == "Lakehouse") | .id')
    
    if [[ -z "${lakehouse_id}" || "${lakehouse_id}" == "null" ]]; then
        log "Lakehouse ${lakehouse_name} not found." "error"
        return 1
    fi
    
    echo "${lakehouse_id}"
    return 0
}
