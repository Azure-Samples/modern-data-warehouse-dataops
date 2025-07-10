#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

#######################################################
# Cleans up all azure and Fabric resources
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

# Source common functions
. ./scripts/common.sh

# Validate required environment variables
validate_required_vars \
    "ENVIRONMENT_NAME" \
    "TENANT_ID" \
    "SUBSCRIPTION_ID" \
    "RESOURCE_GROUP_NAME" \
    "BASE_NAME" \
    "APP_CLIENT_ID" \
    "APP_CLIENT_SECRET" \
    "GIT_ORGANIZATION_NAME" \
    "GIT_PROJECT_NAME" \
    "GIT_REPOSITORY_NAME" \
    "GIT_BRANCH_NAME" \
    "FABRIC_WORKSPACE_ADMIN_SG_NAME"

# Validate required commands
validate_commands "az" "terraform" "jq" "curl"

## Environment variables
environment_name="${ENVIRONMENT_NAME}"
tenant_id="${TENANT_ID}"
subscription_id="${SUBSCRIPTION_ID}"
resource_group_name="${RESOURCE_GROUP_NAME}"
base_name="${BASE_NAME}"
## Service Principal details
client_id="${APP_CLIENT_ID}"
client_secret="${APP_CLIENT_SECRET}"
# GIT integration details
git_organization_name="${GIT_ORGANIZATION_NAME}"
git_project_name="${GIT_PROJECT_NAME}"
git_repository_name="${GIT_REPOSITORY_NAME}"
git_branch_name="${GIT_BRANCH_NAME}"
# Workspace admin variables
fabric_workspace_admin_sg_name="${FABRIC_WORKSPACE_ADMIN_SG_NAME}"
# Fabric Capacity variables
existing_fabric_capacity_name="${EXISTING_FABRIC_CAPACITY_NAME:-}"
fabric_capacity_admins="${FABRIC_CAPACITY_ADMINS:-}"
deploy_fabric_items="${DEPLOY_FABRIC_ITEMS:-}"

## KeyVault secret variables
appinsights_connection_string_name="appinsights-connection-string"

# Git directory name for syncing Fabric workspace items
fabric_workspace_directory="/fabric/workspace"

# Fabric bearer token variables, set globally
fabric_bearer_token=""
fabric_api_endpoint="https://api.fabric.microsoft.com/v1"

# Fabric related variables
adls_gen2_shortcut_name="sc-adls-main"
adls_gen2_shortcut_path="Files"

# Azure DevOps pipelines to be deleted
azdo_pipeline_ci_qa="pl-${base_name}-ci-qa"
azdo_pipeline_ci_qa_cleanup="pl-${base_name}-ci-qa-cleanup"
azdo_pipeline_ci_publish_artifacts="pl-${base_name}-ci-publish-artifacts"

#######################################################
# Set global Azure DevOps configuration
# Arguments:
#   None
# Outputs:
#   Info message about configuration
#######################################################
set_global_azdo_config() {
    log "Setting global Azure DevOps configuration" "info"
    az devops configure --defaults \
        organization="https://dev.azure.com/${git_organization_name}" \
        project="${git_project_name}"
}

#######################################################
# Cleanup terraform resources in specified directory
# Arguments:
#   $1: terraform_directory - Path to terraform directory
# Outputs:
#   Status messages about cleanup progress
#######################################################
cleanup_terraform_resources() {
    local terraform_directory=${1}
    local original_directory=$(pwd)
    
    log "Cleaning up terraform resources in ${terraform_directory}" "info"
    cd "${terraform_directory}" || exit

    local user_principal_type=$(az account show --query user.type --output tsv)
    local use_cli use_msi
    
    if [[ "${user_principal_type}" == "user" ]]; then
        use_cli="true"
        use_msi="false"
    else
        use_cli="false"
        local msi=$(az account show --query user.assignedIdentityInfo --output tsv)
        if [[ -z "${msi}" ]]; then
            use_msi="false"
        else
            use_msi="true"
        fi
    fi
    
    log "'use_cli' is '${use_cli}'" "info"
    log "'use_msi' is '${use_msi}'" "info"
    log "'client_id' is '${client_id}'" "info"
    log "'deploy_fabric_items' is '${deploy_fabric_items}'" "info"

    local create_fabric_capacity
    if [[ -z "${existing_fabric_capacity_name}" ]]; then
        create_fabric_capacity="true"
    else
        create_fabric_capacity="false"
    fi

    log "Switching to terraform '${environment_name}' workspace." "info"
    terraform workspace select --or-create=true "${environment_name}"

    terraform init
    terraform destroy \
        --auto-approve \
        --var "use_cli=${use_cli}" \
        --var "use_msi=${use_msi}" \
        --var "environment_name=${environment_name}" \
        --var "tenant_id=${tenant_id}" \
        --var "subscription_id=${subscription_id}" \
        --var "resource_group_name=${resource_group_name}" \
        --var "base_name=${base_name}" \
        --var "client_id=${client_id}" \
        --var "client_secret=${client_secret}" \
        --var "fabric_workspace_admin_sg_name=${fabric_workspace_admin_sg_name}" \
        --var "create_fabric_capacity=${create_fabric_capacity}" \
        --var "fabric_capacity_name=${existing_fabric_capacity_name}" \
        --var "fabric_capacity_admins=${fabric_capacity_admins}" \
        --var "git_organization_name=${git_organization_name}" \
        --var "git_project_name=${git_project_name}" \
        --var "git_repository_name=${git_repository_name}" \
        --var "git_branch_name=${git_branch_name}" \
        --var "git_directory_name=${fabric_workspace_directory}" \
        --var "fabric_adls_shortcut_name=${adls_gen2_shortcut_name}" \
        --var "kv_appinsights_connection_string_name=${appinsights_connection_string_name}" \
        --var "deploy_fabric_items=${deploy_fabric_items}"

    cd "${original_directory}"
}

#######################################################
# Set Fabric bearer token for API calls
# Arguments:
#   None
# Outputs:
#   Sets fabric_bearer_token global variable
#######################################################
set_bearer_token() {
    log "Setting up fabric bearer token" "info"
    fabric_bearer_token=$(az account get-access-token \
        --resource "https://login.microsoftonline.com/${tenant_id}" \
        --query accessToken \
        --scope "https://analysis.windows.net/powerbi/api/.default" \
        --output tsv)
}

#######################################################
# Delete a Fabric connection if it exists
# Arguments:
#   $1: connection_id - ID of the connection to delete
# Outputs:
#   Status messages about deletion result
#######################################################
delete_connection() {
    local connection_id=${1}
    local delete_connection_url="${fabric_api_endpoint}/connections/${connection_id}"

    local response=$(curl --silent --request DELETE \
        --header "Authorization: Bearer ${fabric_bearer_token}" \
        "${delete_connection_url}")

    if [[ -z "${response}" ]]; then
        log "Connection '${connection_id}' deleted successfully." "success"
    else
        log "Failed to delete connection '${connection_id}'." "error"
        log "${response}" "error"
    fi
}

#######################################################
# Clean up terraform intermediate files
# Arguments:
#   None
# Outputs:
#   Status messages about cleanup progress
#######################################################
cleanup_terraform_files() {
    log "Cleaning up terraform intermediate files" "info"
    
    # List and delete .terraform directories
    log "Listing Terraform state directory that will be deleted:" "info"
    find . -type d -name "${environment_name}" -path "*/terraform.tfstate.d/*"
    find . -type d -name "${environment_name}" -path "*/terraform.tfstate.d/*" -exec rm -rf {} + 2>/dev/null || true
    
    log "Listing '.terraform' directory that will be deleted:" "info"
    find . -type d -name ".terraform"
    find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
    
    log "Terraform directories deleted successfully." "success"

    # List and delete specific Terraform files
    log "Listing Terraform lock file that will be deleted:" "info"
    find . -type f -name ".terraform.lock.hcl"
    find . -type f -name ".terraform.lock.hcl" -exec rm -f {} + 2>/dev/null || true
    
    log "Terraform lock file deleted successfully." "success"
}

#######################################################
# Clean up Azure DevOps pipeline files
# Arguments:
#   None
# Outputs:
#   Status messages about cleanup progress
#######################################################
cleanup_azdo_pipeline_files() {
    log "Cleaning up Azure DevOps pipeline files" "info"
    
    # List and delete Azure DevOps pipeline files
    log "Listing Azure DevOps pipeline files that will be deleted:" "info"
    find ./devops -maxdepth 1 -type f -name "*.yml"
    find ./devops -maxdepth 1 -type f -name "*.yml" -exec rm -f {} + 2>/dev/null || true
    
    log "Azure DevOps pipeline files deleted successfully." "success"
}

#######################################################
# Get connection ID by name
# Arguments:
#   $1: connection_name - Name of the connection
# Outputs:
#   Connection ID
#######################################################
get_connection_id_by_name() {
    local connection_name=${1}
    local list_connection_url="${fabric_api_endpoint}/connections"
    
    local response=$(curl --silent --request GET \
        --header "Authorization: Bearer ${fabric_bearer_token}" \
        --header "Content-Type: application/json" \
        "${list_connection_url}")
    
    local connection_id=$(echo "${response}" | jq --raw-output \
        --arg name "${connection_name}" \
        '.value[] | select(.displayName == $name) | .id')
    
    echo "${connection_id}"
}

get_azdo_pipeline_id () {
  local pipeline_name=$1
  local pipeline_output=$(az pipelines list --query "[?name=='$pipeline_name']" --output json)
  local pipeline_id=$(echo "$pipeline_output" | jq -r '.[0].id')
  echo "$pipeline_id"
}

#######################################################
# Delete Azure DevOps pipeline if it exists
# Arguments:
#   $1: pipeline_name - Name of the pipeline to delete
# Outputs:
#   Status messages about deletion result
#######################################################
delete_azdo_pipeline() {
    local pipeline_name=${1}
    local pipeline_id=$(get_azdo_pipeline_id "${pipeline_name}")

    if [[ -z "${pipeline_id}" || "${pipeline_id}" == "null" ]]; then
        log "No AzDo pipeline with name '${pipeline_name}' found." "info"
    else
        az pipelines delete --id "${pipeline_id}" --yes >/dev/null 2>&1
        log "Deleted pipeline '${pipeline_name}' (Pipeline ID: '${pipeline_id}')" "success"
    fi
}

# Main cleanup flow
log "############ STARTING CLEANUP STEPS ############" "info"

log "############ Destroy terraform resources ############" "info"
cleanup_terraform_resources "./infrastructure/terraform"
log "############ Terraform resources destroyed ############" "success"

log "############ Setting up fabric bearer token ############" "info"
set_bearer_token

log "############ ADLS Gen2 connection deletion ############" "info"
# Deriving ADLS Gen2 connection name instead of relying on Terraform output for idempotency
adls_gen2_connection_name="conn-adls-st${base_name//[-_]/}${environment_name}"

adls_gen2_connection_id=$(get_connection_id_by_name "${adls_gen2_connection_name}")

if [[ -z "${adls_gen2_connection_id}" || "${adls_gen2_connection_id}" == "null" ]]; then
    log "No Fabric connection with name '${adls_gen2_connection_name}' found, skipping deletion." "warning"
else
    log "Fabric Connection details: '${adls_gen2_connection_name}' (${adls_gen2_connection_id})" "info"
    delete_connection "${adls_gen2_connection_id}"
fi

log "############ Cleanup Terraform Intermediate files (state, lock etc.,) ############" "info"
cleanup_terraform_files

log "############ Deleting AzDo Pipelines ############" "info"
set_global_azdo_config

delete_azdo_pipeline "${azdo_pipeline_ci_qa}"
delete_azdo_pipeline "${azdo_pipeline_ci_qa_cleanup}"
delete_azdo_pipeline "${azdo_pipeline_ci_publish_artifacts}"

log "############ Cleanup AzDo Pipeline files ('/devops/*.yml') ############" "info"
cleanup_azdo_pipeline_files

log "############ FINISHED INFRA CLEANUP ############" "success"
