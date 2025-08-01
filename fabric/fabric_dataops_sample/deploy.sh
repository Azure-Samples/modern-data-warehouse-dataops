#!/bin/bash

# Set partner ID for telemetry. For usage details, see https://github.com/microsoft/modern-data-warehouse-dataops/blob/main/README.md#data-collection
export AZURE_HTTP_USER_AGENT="acce1e78-fb84-2ec8-240c-c457cfba34ad"

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

# Source common functions
. ./scripts/common.sh

# Source environment variables
source ./.env

. ./scripts/verify_prerequisites.sh "./.env"

# Log all outputs and errors to a log file
log_file="deploy_${BASE_NAME}_$(date +"%Y%m%d_%H%M%S").log"
exec > >(tee -a "${log_file}")
exec 2>&1

log "Starting deployment process" "info"

# Global variable to capture the first environment ("dev") branch name
azdo_policies_branch_name=""
# Global variable to capture the last environment ("prod") branch name
azdo_pipelines_branch_name=""

for i in "${!ENVIRONMENT_NAMES[@]}"; do
    log "Processing environment ${i}: ${ENVIRONMENT_NAMES[$i]}" "info"
    
    if [[ "${i}" -eq 0 ]]; then
        deploy_fabric_items="true"
        azdo_policies_branch_name="${GIT_BRANCH_NAMES[$i]}"
    else
        deploy_fabric_items="false"
    fi

    azdo_pipelines_branch_name="${GIT_BRANCH_NAMES[$i]}"

    ENVIRONMENT_NAME="${ENVIRONMENT_NAMES[$i]}" \
    RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAMES[$i]}" \
    TENANT_ID="${TENANT_ID}" \
    SUBSCRIPTION_ID="${SUBSCRIPTION_ID}" \
    BASE_NAME="${BASE_NAME}" \
    APP_CLIENT_ID="${APP_CLIENT_ID}" \
    APP_CLIENT_SECRET="${APP_CLIENT_SECRET}" \
    GIT_ORGANIZATION_NAME="${GIT_ORGANIZATION_NAME}" \
    GIT_PROJECT_NAME="${GIT_PROJECT_NAME}" \
    GIT_REPOSITORY_NAME="${GIT_REPOSITORY_NAME}" \
    GIT_BRANCH_NAME="${GIT_BRANCH_NAMES[$i]}" \
    FABRIC_WORKSPACE_ADMIN_SG_NAME="${FABRIC_WORKSPACE_ADMIN_SG_NAME}" \
    EXISTING_FABRIC_CAPACITY_NAME="${EXISTING_FABRIC_CAPACITY_NAME}" \
    FABRIC_CAPACITY_ADMINS="${FABRIC_CAPACITY_ADMINS}" \
    DEPLOY_FABRIC_ITEMS="${deploy_fabric_items}" \
    bash -c "./scripts/deploy_infrastructure.sh"
done

# Deploy Azure DevOps pipelines and create branch policies
user_principal_type=$(az account show --query user.type --output tsv)
if [[ "${user_principal_type}" == "user" ]]; then
    log "Deploying Azure DevOps pipelines" "info"
    AZDO_ORGANIZATION_NAME="${GIT_ORGANIZATION_NAME}" \
    AZDO_PROJECT_NAME="${GIT_PROJECT_NAME}" \
    AZDO_REPOSITORY_NAME="${GIT_REPOSITORY_NAME}" \
    AZDO_PIPELINES_BRANCH_NAME="${azdo_pipelines_branch_name}" \
    AZDO_POLICIES_BRANCH_NAME="${azdo_policies_branch_name}" \
    BASE_NAME="${BASE_NAME}" \
    bash -c "./scripts/deploy_azdo_pipelines.sh"
else
    log "Skipping Azure DevOps pipelines deployment as those are deployed using the user context." "warning"
fi

log "Deployment process completed" "success"
