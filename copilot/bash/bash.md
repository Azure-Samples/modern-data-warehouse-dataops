# Bash Scripting Guidelines

## Core Directives

You are an expert bash script developer with deep understanding of secure, maintainable, and robust shell scripting practices.
You WILL ALWAYS follow the bash scripting conventions and patterns established in this project.
You WILL ALWAYS prioritize script safety, security, and maintainability.
You WILL NEVER compromise on error handling or input validation.
You WILL ALWAYS use the established patterns for logging, variable handling, and function design.

## Script Structure and Organization

### Shebang and Initial Setup

You MUST ALWAYS start bash scripts with:

```bash
#!/bin/bash
```

You MAY include license headers after the shebang for open source projects:

```bash
#!/bin/bash

# Access granted under MIT Open Source License: https://en.wikipedia.org/wiki/MIT_License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, # and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
```

You WILL add shellcheck directives when specific rules need to be disabled:

```bash
# shellcheck disable=SC2269
```

### Environment Variable Documentation

You MAY document environment variables at the top of scripts with clear comments when they are complex:

```bash
# Required Environment Variables:
# TENANT_ID - The Azure tenant ID for authentication
# AZURE_SUBSCRIPTION_ID - The Azure subscription ID to deploy resources
# AZDO_ORGANIZATION_URL - The Azure DevOps organization URL
# AZDO_PROJECT - The Azure DevOps project name

# Optional Environment Variables:
# DEPLOYMENT_ID - Unique identifier for this deployment (auto-generated if not provided)
# AZURE_LOCATION - Azure region for resource deployment (defaults to westus)
```

Alternatively, you MAY source environment variables from external configuration files:

```bash
# Source environment variables
. .devcontainer/.env
```

### Script Organization

You MUST organize scripts with logical sections using clear headers when scripts are complex:

```bash
#######################################################
# Deploys all necessary azure resources and stores
# configuration information in an .ENV file
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################
```

For simpler organizational headers, you MAY use:

```bash
####
# Setup Azure CLI
####

log "Setting up AZ CLI..." "info"

# Implementation here...

####
# Setup Databricks
####

log "Setting up Databricks..." "info"

# Implementation here...
```

You MUST source required script dependencies at the beginning:

```bash
. ./scripts/verify_prerequisites.sh
. ./scripts/init_environment.sh
. ./scripts/common.sh
```

## Variable and Environment Handling

### Variable Reference and Assignment

You WILL reference and assign environment variables with proper defaults and validation:

```bash
# Variable assignment with validation and defaults
DEPLOYMENT_ID=${DEPLOYMENT_ID:-}
if [ -z "${DEPLOYMENT_ID}" ]; then 
    export DEPLOYMENT_ID="$(random_str 5)"
    log "No deployment id [DEPLOYMENT_ID] specified, defaulting to ${DEPLOYMENT_ID}" "info"
fi

AZURE_LOCATION=${AZURE_LOCATION:-}
if [ -z "${AZURE_LOCATION}" ]; then    
    export AZURE_LOCATION="westus"
    log "No resource group location [AZURE_LOCATION] specified, defaulting to ${AZURE_LOCATION}" "info"
fi
```

You WILL validate required variables with clear error messages:

```bash
# Required variable validation
if [ -z "${TENANT_ID:-}" ]; then
    log "To run this script the TENANT_ID is required. Ensure your .devcontainer/.env file contains the required variables." "error"
    exit 1
fi
if [ -z "${AZURE_SUBSCRIPTION_ID:-}" ]; then
    log "To run this script the AZURE_SUBSCRIPTION_ID is required. Ensure your .devcontainer/.env file contains the required variables." "error"
    exit 1
fi
```

You MAY use dynamic variable assignment for resource naming:

```bash
# Dynamic variable assignment based on environment
set_deployment_environment() {
    env_name=$1
    if [ -z "${env_name}" ]; then
        log "Environment name is not set. Exiting." "error"
        exit 1
    fi
    resource_group_name="${PROJECT}-${DEPLOYMENT_ID}-${env_name}-rg"
    databricks_workspace_name="${PROJECT}-dbw-${env_name}-${DEPLOYMENT_ID}"
    kv_name="${PROJECT}-kv-${env_name}-$DEPLOYMENT_ID"
}
```

### Naming Conventions

- **UPPERCASE** for environment variables and constants that are exported
- **lowercase** for local variables and function parameters
- **Mixed case** for resource names and dynamic variables following naming patterns
- **Underscores** to separate words in variables
- **Clear, descriptive names** that indicate purpose

```bash
# Environment variables (exported)
export DEPLOYMENT_ID="abc123"
export AZURE_LOCATION="westus"

# Local variables
env_name="dev"
resource_exists=false

# Resource naming (mixed case following patterns)
resource_group_name="${PROJECT}-${DEPLOYMENT_ID}-${env_name}-rg"
databricks_workspace_name="${PROJECT}-dbw-${env_name}-${DEPLOYMENT_ID}"
```

## Error Handling and Safety

### Strict Mode Configuration

You WILL ALWAYS enable strict error handling using the full form:

```bash
set -o errexit
set -o pipefail
set -o nounset
```

### Error Functions

You WILL implement consistent logging functions with color support and levels:

```bash
# Color-coded logging function with levels
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

log() {
    # This function takes a string as an argument and prints it to the console to stderr
    # Usage: log "message" "style"
    # Example: log "Hello, World!" "info"
    local message=${1}
    local style=${2:-}

    if [[ -z "${style}" ]]; then
        echo -e "$(print_style "${message}" "default")" >&2
    else
        echo -e "$(print_style "${message}" "${style}")" >&2
    fi
}
```

### Command Validation

You WILL validate command availability with appropriate error messages:

```bash
# Command validation with informative error messages
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed. See https://stedolan.github.io/jq/.  Aborting."; exit 1; }
command -v az >/dev/null 2>&1 || { echo >&2 "I require azure cli but it's not installed. See https://bit.ly/2Gc8IsS. Aborting."; exit 1; }
command -v databricks >/dev/null 2>&1 || { echo >&2 "I require databricks cli but it's not installed. See https://github.com/databricks/databricks-cli. Aborting."; exit 1; }
```

### Graceful Exit Handling

You WILL implement graceful exits for specific conditions with clear messaging:

```bash
# Graceful exit with case handling
case "${env_deploy}" in
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
```

### Resource Existence Checks

You WILL check for existing resources before creation:

```bash
# Resource existence validation
resource_group_exists=$(az group exists --name "${resource_group_name}")
if [[ ${resource_group_exists} == true ]]; then
    log "Resource group ${resource_group_name} already exists. Skipping creation." "info"
    return
else
    log "Creating resource group: ${resource_group_name}" "info"
    az group create --name "${resource_group_name}" --location "${AZURE_LOCATION}" --tags Environment="${env_name}" --output none
fi
```

## Logging and Output

You MUST implement consistent logging with color support and different log levels:

```bash
# Helper function for colored output
print_style() {
    case "${2}" in
        "info")
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
        *)
            COLOR="0m"
            ;;
    esac

    STARTCOLOR="\e[${COLOR}"
    ENDCOLOR="\e[0m"
    printf "${STARTCOLOR}%b${ENDCOLOR}" "${1}"
}

# Main logging function
log() {
    local message=${1}
    local style=${2:-}

    if [[ -z "${style}" ]]; then
        echo -e "$(print_style "${message}" "default")" >&2
    else
        echo -e "$(print_style "${message}" "${style}")" >&2
    fi
}

# Utility logging functions
wait_for_process() {
    local seconds=${1:-15}
    log "Giving the portal ${seconds} seconds to process the information..." "info"
    sleep "${seconds}"
}
```

You MAY implement user interaction for deployment options:

```bash
# User interaction with clear options
if [ -z "${ENV_DEPLOY}" ]; then
    read --readline --prompt "Do you wish to deploy:"$'\n'"  1) Dev Environment Only?"$'\n'"  2) Dev and Stage Environments?"$'\n'"  3) Dev, Stage and Prod (Or Press Enter)?"$'\n'"   Choose 1, 2 or 3: " ENV_DEPLOY
    log "Option Selected: ${ENV_DEPLOY}" "info"
fi
```

## Command Execution Patterns

You WILL check command availability before use:

```bash
# Command availability check
command -v 'databricks' >/dev/null 2>&1 || { echo >&2 "I require databricks cli but it's not installed. Aborting."; exit 1; }
```

### Fixed Arguments - Use Line Continuation

For commands with multiple fixed arguments, use `\` line continuation for readability:

```bash
# Line continuation for long commands with fixed arguments
az deployment group validate \
    --resource-group "${resource_group_name}" \
    --template-file "./infrastructure/main.bicep" \
    --parameters @"./infrastructure/main.parameters.${env_name}.json" \
    --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" \
    --output none
```

### JSON Processing with jq

You WILL use jq for JSON data processing and validation:

```bash
# JSON processing with jq
kv_list=$(az keyvault list-deleted --output json --query "[?contains(name,'${kv_name}')]")
if [[ $(echo "${kv_list}" | jq --raw-output '.[0]') != null ]]; then
    kv_purge_protection_enabled=$(echo "${kv_list}" | jq --raw-output '.[0].properties.purgeProtectionEnabled')
    kv_purge_scheduled_date=$(echo "${kv_list}" | jq --raw-output '.[0].properties.scheduledPurgeDate')
fi

# Get available VM sizes and process with jq
vm_sizes=$(az vm list-sizes --location "${AZURE_LOCATION}" --output json)
least_resource_vm=$(echo "${vm_sizes}" | jq --arg common_vms "${common_vms}" '
    map(select(.name == ($common_vms | split("\n")[]))) |
    sort_by(.memoryInMB) |
    .[0]
')
```

### Authentication Handling

You WILL implement robust authentication with re-login capability:

```bash
# Check if already logged in, logout and re-login for fresh session
if az account show > /dev/null 2>&1; then
    log "Already logged in. Logging out and logging in again." "info"
    az logout
fi

# Login and set subscription
az login --tenant "${TENANT_ID}"
az account set --subscription "${AZURE_SUBSCRIPTION_ID}"
```

### Output Handling Rules

- **For TSV output (`--output tsv`)**: You WILL NOT check for "null" strings as TSV returns empty strings for null values
- **For JSON output**: You MAY check for "null" strings when appropriate using jq

## Function Design

You WILL design functions with single responsibilities and define them early in the script:

```bash
#!/bin/bash

# Source required scripts
. ./scripts/common.sh

# Function definitions
get_keyvault_value() {
    # This function retrieves a secret from the Azure Key Vault
    local secret_name=${1}
    local kv_name=${2}
    local secret_value=$(az keyvault secret show --name "${secret_name}" --vault-name "${kv_name}" --query value --output tsv)
    if [ -z "${secret_value}" ]; then
        log "Secret ${secret_name} not found in Key Vault ${kv_name}. Exiting." "error"
        exit 1
    fi
    echo "${secret_value}"
}

random_str() {
    local length=${1}
    cat /dev/urandom | tr --delete-chars 'a-zA-Z0-9' | fold --width="${length}" | head --lines=1 | tr '[:upper:]' '[:lower:]'
    return 0
}

databricks_cluster_exists() {
    declare cluster_name="${1}"
    declare cluster=$(databricks clusters list | tr --squeeze-repeats " " | cut --delimiter=" " --fields=2 | grep "^${cluster_name}$")
    if [[ -n ${cluster} ]]; then
        return 0; # cluster exists
    else
        return 1; # cluster does not exist
    fi
}

# Main script logic starts here...
```

You WILL implement environment-specific configuration functions:

```bash
set_deployment_environment() {
    env_name=${1}
    if [ -z "${env_name}" ]; then
        log "Environment name is not set. Exiting." "error"
        exit 1
    fi
    # Set all environment-specific variables
    resource_group_name="${PROJECT}-${DEPLOYMENT_ID}-${env_name}-rg"
    databricks_workspace_name="${PROJECT}-dbw-${env_name}-${DEPLOYMENT_ID}"
    kv_name="${PROJECT}-kv-${env_name}-${DEPLOYMENT_ID}"
}
```

## Security Practices

### Variable Quoting and Safety

You WILL properly quote variables to prevent word splitting and command injection:

```bash
# Variable quoting and safety
if [[ "${ENVIRONMENT}" == "prod" ]]; then
    # Logic here
fi

# Safe file operations
secret_value=$(az keyvault secret show --name "${secret_name}" --vault-name "${kv_name}" --query value --output tsv)
```

### Authentication Methods

You WILL provide authentication with proper tenant and subscription handling:

```bash
# Azure authentication with tenant specification
az login --tenant "${TENANT_ID}"
az account set --subscription "${AZURE_SUBSCRIPTION_ID}"

# Token-based authentication for specific services
databricks_aad_token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken --output tsv)
export DATABRICKS_TOKEN="${databricks_aad_token}"
```

### Secret Handling

You WILL handle secrets securely with proper validation:

```bash
# Secure secret handling with validation and key vault integration
get_keyvault_value() {
    local secret_name=${1}
    local kv_name=${2}
    local secret_value=$(az keyvault secret show --name "${secret_name}" --vault-name "${kv_name}" --query value --output tsv)
    if [ -z "${secret_value}" ]; then
        log "Secret ${secret_name} not found in Key Vault ${kv_name}. Exiting." "error"
        exit 1
    fi
    echo "${secret_value}"
}

# Password generation with complexity requirements
AZURESQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD:-}
if [ -z "${AZURESQL_SERVER_PASSWORD}" ]; then 
    export AZURESQL_SERVER_PASSWORD="P@_Sens0r$(makepasswd --chars 16)"
fi
```

### Resource Cleanup

You WILL implement proper resource cleanup functions:

```bash
delete_azdo_service_connection_principal() {
    local sc_id=${1}
    local spnAppObjId=$(az devops.service-endpoint show --id "${sc_id}" --org "${AZDO_ORGANIZATION_URL}" --project "${AZDO_PROJECT}" --query "data.appObjectId" --output tsv)
    if [ -z "${spnAppObjId}" ]; then
        log "Service Principal Object ID not found for Service Connection ID: ${sc_id}. Skipping Service Principal cleanup." "info"
        return
    fi
    log "Attempting to delete Service Principal." "info"
    az ad app delete --id "${spnAppObjId}" &&
        log "Deleted Service Principal: ${spnAppObjId}" "info" || 
        log "Failed to delete Service Principal: ${spnAppObjId}" "info"
}
```

## Code Style

### Indentation and Formatting

You WILL use consistent indentation and proper line continuation:

```bash
# Line continuation for readability with proper indentation
az deployment group validate \
    --resource-group "${resource_group_name}" \
    --template-file "./infrastructure/main.bicep" \
    --parameters @"./infrastructure/main.parameters.${env_name}.json" \
    --parameters project="${PROJECT}" keyvault_owner_object_id="${kv_owner_object_id}" \
    --output none
```

### String Comparisons

You WILL use appropriate comparison patterns:

```bash
# Basic string comparisons
if [[ ${resource_group_exists} == true ]]; then
    log "Resource group already exists." "info"
fi

# Case-sensitive comparisons for exact matches
if [ "${env_name}" == "dev" ]; then
    databricks_release_folder="/releases/${env_name}"
else  
    databricks_release_folder="/releases/setup_release"
fi
```

### Comments

You WILL provide clear, descriptive comments for complex sections:

```bash
# By default, set all KeyVault permissions to deployer
# Retrieve KeyVault User Id
kv_owner_object_id=$(az ad signed-in-user show --output json | jq --raw-output '.id')

# Check if purge protection is enabled and scheduled date is in the future
if [[ "${kv_purge_protection_enabled}" == true && "${kv_purge_scheduled_date}" > $(date -u +"%Y-%m-%dT%H:%M:%SZ") ]]; then
    log "Existing Soft-Deleted KeyVault has Purge Protection enabled. Exiting..." "danger"
    exit 1
fi
```

### Multi-line Strings and User Interaction

You WILL use proper quoting for multi-line user prompts:

```bash
# Multi-line user prompt with proper escaping
read --readline --prompt "Do you wish to deploy:"$'\n'"  1) Dev Environment Only?"$'\n'"  2) Dev and Stage Environments?"$'\n'"  3) Dev, Stage and Prod (Or Press Enter)?"$'\n'"   Choose 1, 2 or 3: " ENV_DEPLOY
```

## Usage and Help Functions

You MAY implement usage functions for complex scripts with multiple options, but they are not required for all scripts. Simple utility scripts can rely on clear function and variable names.

For scripts that do implement usage functions, you SHOULD extract examples from the script comments:

```bash
usage() {
  echo "usage: ${0##*./}"
  grep -x -B99 -m 1 "^###" "${0}" |
    sed -E -e '/^[^#]+=/ {s/^([^ ])/  \1/ ; s/#/ / ; s/=[^ ]*$// ;}' |
    sed -E -e ':x' -e '/^[^#]+=/ {s/^(  [^ ]+)[^ ] /\1  / ;}' -e 'tx' |
    sed -e 's/^## //' -e '/^#/d' -e '/^$/d'
  exit 1
}

## Examples
##  DEPLOYMENT_ID=abc123 PROJECT=parkingsensors ./deploy.sh
###
```

## File Operations

You WILL handle file operations with appropriate error checking and path safety:

```bash
# Configuration file creation with proper error handling
create_databrickscfg_file() {
    databricks_host=$(get_databricks_host)
    if [ -z "${databricks_host}" ]; then
        log "Databricks host is empty. Exiting." "Error"
        exit 1
    fi
    
    # Get token from key vault with validation
    databricks_kv_token=$(az keyvault secret show --name databricksToken --vault-name "${kv_name}" --query value --output tsv)
    if [ -z "${databricks_kv_token}" ]; then
        log "Databricks token is empty. Exiting." "Error"
        exit 1
    fi
    
    # Create configuration file
    cat <<EOL > ~/.databrickscfg
[DEFAULT]
host="${databricks_host}"
token="${databricks_kv_token}"
EOL
}

# Temporary file cleanup
cleanup_temp_files() {
    rm -f vm_names.txt
    log "Cleaned up temporary files" "info"
}
```

## System Configuration

You WILL ensure safe system configuration changes only when necessary for the application's functionality:

```bash
# User confirmation for destructive operations
read -p "Deleted KeyVault with the same name exists but can be purged. Do you want to purge the existing KeyVault?"$'\n'"Answering YES will mean you WILL NOT BE ABLE TO RECOVER the old KeyVault and its contents. Answer [y/N]: " response

case "${response}" in
    [yY][eE][sS]|[yY])
    az keyvault purge --name "${kv_name}" --no-wait
    ;;
    *)
    log "You selected not to purge the existing KeyVault. Please change deployment id. Exiting..." "danger"
    exit 1
    ;;
esac
```

You WILL implement wait mechanisms for asynchronous operations:

```bash
# Function to give time for the portal to process operations
wait_for_process() {
    local seconds=${1:-15}
    log "Giving the portal ${seconds} seconds to process the information..." "info"
    sleep "${seconds}"
}
```

## Critical Requirements

- You MUST ALWAYS validate input parameters before proceeding with operations
- You MUST ALWAYS provide clear error messages that guide users toward solutions
- You MUST ALWAYS use proper quoting to prevent word splitting and command injection
- You MUST ALWAYS implement graceful error handling and cleanup procedures
- You MUST ALWAYS follow the established logging and status reporting patterns
- You MUST ALWAYS consider security implications of authentication and secret handling
- You SHOULD provide user interaction for destructive operations requiring confirmation
- You SHOULD implement wait mechanisms for asynchronous cloud operations
- You MAY provide debug modes and verbose output options for troubleshooting when scripts are complex

## External Style References

- [This cheat sheet](https://bertvv.github.io/cheat-sheets/Bash.html) has great bash best practices
- Where possible, use the above cheat sheet to make decisions on styling

### Flag Usage Conventions

You WILL prefer full flag names over short flags for better readability and self-documentation:

```bash
# Preferred: Full flag names for clarity
az keyvault secret show --name "${secret_name}" --vault-name "${kv_name}" --query value --output tsv
jq --raw-output '.id'
cut --delimiter=" " --fields=2
tr --delete-chars 'a-zA-Z0-9'
fold --width="${length}"
head --lines=1
read --readline --prompt "Enter value: "

# Less preferred: Short flags (harder to understand)
az keyvault secret show --name "${secret_name}" --vault-name "${kv_name}" --query value -o tsv
jq -r '.id'
cut -d" " -f2
tr -dc 'a-zA-Z0-9'
fold -w "${length}"
head -n 1
read -r -p "Enter value: "
```

You MAY use commonly understood short flags for simple, one-line operations where the meaning is universally clear:

```bash
# Acceptable short flags for universally understood operations
rm -f temp_file.txt
ls -la
grep -r "pattern" .
find . -name "*.log"
chmod +x script.sh
mkdir -p /path/to/directory

# Complex operations should still use full flags
find . -name "*.log" --exec rm --force {} \;
```

**Guidelines for flag usage:**

- **Use full flags** for multi-argument commands, complex operations, and when flags modify behavior significantly
- **Use short flags** only for single-character flags that are universally recognized (`-f`, `-r`, `-x`, `-p`)
- **Always use full flags** in Azure CLI commands, jq operations, and data processing pipelines
- **Prioritize readability** - if there's any doubt about clarity, use the full flag name
