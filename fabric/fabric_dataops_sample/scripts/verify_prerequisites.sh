#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

# Source common functions
. ./scripts/common.sh

log "############ STARTING PRE REQUISITE CHECK ############" "info"

ENV_FILE="${1:-../.env}"

#######################################################
# Check if Python 3 is installed and meets version requirements
# Arguments:
#   None
# Outputs:
#   Status messages about Python version
# Returns:
#   Exits with 1 if Python requirements are not met
#######################################################
check_python_version() {
    if ! command_exists python3; then
        log "Python is not installed or not available in PATH." "error"
        exit 1
    fi

    local python_interpreter=$(which python3)
    log "Using Python interpreter: ${python_interpreter}" "info"

    local python_version=$(python3 --version 2>&1)
    log "${python_version} found." "info"

    local python_version_major=$(python3 -c "import sys; print(sys.version_info.major)")
    local python_version_minor=$(python3 -c "import sys; print(sys.version_info.minor)")

    if [[ "${python_version_major}" -lt 3 || ("${python_version_major}" -eq 3 && "${python_version_minor}" -lt 9) ]]; then
        log "Python version ${python_version_major}.${python_version_minor} found. Python 3.9 or higher is required." "error"
        exit 1
    fi
    
    log "Python version ${python_version_major}.${python_version_minor} is installed and meets the requirement (>= 3.9)." "success"
}

#######################################################
# Check if required Python libraries are installed
# Arguments:
#   None
# Outputs:
#   Status messages about library availability
# Returns:
#   Exits with 1 if required libraries are missing
#######################################################
check_python_libraries() {
    local libraries=("requests")
    
    for library in "${libraries[@]}"; do
        if ! python3 -m pip show "${library}" &>/dev/null; then
            log "'${library}' library is not installed." "error"
            exit 1
        fi
        log "'${library}' library is installed." "success"
    done
}

#######################################################
# Check if Terraform is installed and meets version requirements
# Arguments:
#   None
# Outputs:
#   Status messages about Terraform version
# Returns:
#   Exits with 1 if Terraform is not available
#######################################################
check_terraform() {
    if ! command_exists terraform; then
        log "Terraform is not installed or not available in PATH." "error"
        exit 1
    fi

    local terraform_version=$(terraform version | awk '{if ($1 == "Terraform") print $2}')

    if [[ $? -ne 0 || -z "${terraform_version}" ]]; then
        log "Failed to retrieve Terraform version." "error"
        exit 1
    fi

    log "Terraform version ${terraform_version} is installed." "success"
}

#######################################################
# Check if Azure CLI is installed and meets version requirements
# Arguments:
#   None
# Outputs:
#   Status messages about Azure CLI version
# Returns:
#   Exits with 1 if Azure CLI is not available
#######################################################
check_azure_cli() {
    if ! command_exists az; then
        log "Azure CLI is not installed or not available in PATH." "error"
        exit 1
    fi
    
    local azure_cli_version=$(az --version | head --lines=1 | awk '{if ($1 == "azure-cli") print $2}')
    log "Azure CLI version ${azure_cli_version} is installed." "success"
}

#######################################################
# Check if jq (command-line JSON processor) is installed
# Arguments:
#   None
# Outputs:
#   Status messages about jq availability
# Returns:
#   Exits with 1 if jq is not available
#######################################################
check_jq() {
    if ! command_exists jq; then
        log "'jq' is not installed or not available in PATH. You can install 'jq' using: sudo apt-get install jq (for Ubuntu)." "error"
        exit 1
    fi
    
    log "'jq' is installed." "success"
}

#######################################################
# Check if required environment variables are set and non-empty
# Arguments:
#   None
# Outputs:
#   Status messages about environment variables
# Returns:
#   Exits with 1 if required variables are missing
#######################################################
check_env_vars() {
    if [[ ! -f "${ENV_FILE}" ]]; then
        log ".env file not found at ${ENV_FILE}" "error"
        exit 1
    fi

    local compulsory_vars=("TENANT_ID" "SUBSCRIPTION_ID" "BASE_NAME" "FABRIC_WORKSPACE_ADMIN_SG_NAME" "FABRIC_CAPACITY_ADMINS")
    local missing_compulsory_vars=()

    for var in "${compulsory_vars[@]}"; do
        if [[ -z "${!var-}" ]]; then
            missing_compulsory_vars+=("${var}")
        fi
    done

    if [[ ${#missing_compulsory_vars[@]} -gt 0 ]]; then
        log "The following compulsory environment variables are missing or empty:" "error"
        for var in "${missing_compulsory_vars[@]}"; do
            log "  - ${var}" "error"
        done
        log "Please set the above variables or source the .env file." "error"
        exit 1
    fi

    # Ensure 'ENVIRONMENT_NAMES' and 'RESOURCE_GROUP_NAMES' arrays have the same length
    if [[ ${#ENVIRONMENT_NAMES[@]} -ne ${#RESOURCE_GROUP_NAMES[@]} ]]; then
        log "ENVIRONMENT_NAMES and RESOURCE_GROUP_NAMES arrays must have the same length." "error"
        exit 1
    fi

    # Ensure 'ENVIRONMENT_NAMES' and 'GIT_BRANCH_NAMES' arrays have the same length
    if [[ ${#ENVIRONMENT_NAMES[@]} -ne ${#GIT_BRANCH_NAMES[@]} ]]; then
        log "ENVIRONMENT_NAMES and GIT_BRANCH_NAMES arrays must have the same length." "error"
        exit 1
    fi

    log "All compulsory environment variables are set and non-empty." "success"
}

# Main flow
check_python_version
check_python_libraries
check_terraform
check_azure_cli
check_jq
check_env_vars

log "############ PRE REQUISITE CHECK FINISHED ############" "success"
