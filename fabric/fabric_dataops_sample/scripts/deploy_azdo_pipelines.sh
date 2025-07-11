#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

# Source common functions
. ./scripts/common.sh

###################
# REQUIRED ENV VARIABLES:
#
# AZDO_ORGANIZATION_NAME
# AZDO_PROJECT_NAME
# AZDO_REPOSITORY_NAME
# AZDO_PIPELINES_BRANCH_NAME
# AZDO_POLICIES_BRANCH_NAME
# BASE_NAME
###################

# Validate required environment variables
validate_required_vars \
    "AZDO_ORGANIZATION_NAME" \
    "AZDO_PROJECT_NAME" \
    "AZDO_REPOSITORY_NAME" \
    "AZDO_PIPELINES_BRANCH_NAME" \
    "AZDO_POLICIES_BRANCH_NAME" \
    "BASE_NAME"

# AzDo Pipeline name variables
azdo_pipeline_ci_qa="pl-${BASE_NAME}-ci-qa"
azdo_pipeline_ci_qa_cleanup="pl-${BASE_NAME}-ci-qa-cleanup"
azdo_pipeline_ci_publish_artifacts="pl-${BASE_NAME}-ci-publish-artifacts"
azdo_pipeline_variable_pr_id="PR_ID"

get_azdo_repo_id () {
  local repo_name=$1
  local repo_output=$(az repos list --query "[?name=='$repo_name']" --output json)
  local repo_id=$(echo "$repo_output" | jq -r '.[0].id')
  echo "$repo_id"
}

get_azdo_pipeline_id () {
  local pipeline_name=$1
  local pipeline_output=$(az pipelines list --query "[?name=='$pipeline_name']" --output json)
  local pipeline_id=$(echo "$pipeline_output" | jq -r '.[0].id')
  echo "$pipeline_id"
}

#######################################################
# Validate required environment variables and repository existence
# Arguments:
#   None
# Outputs:
#   Error messages for missing variables or repository
# Returns:
#   Exits with 1 if validation fails
#######################################################
validate_env_vars() {
    local repo_id=$(get_azdo_repo_id "${AZDO_REPOSITORY_NAME}")
    
    if [[ -z "${repo_id}" || "${repo_id}" == "null" ]]; then
        log "No Azure DevOps (AzDo) repository with name '${AZDO_REPOSITORY_NAME}' found." "error"
        exit 1
    fi
    
    log "Repository '${AZDO_REPOSITORY_NAME}' found with ID: ${repo_id}" "success"
}

set_global_azdo_config() {
  # Set the global Azure DevOps (AzDo) configuration
  az devops configure --defaults organization="https://dev.azure.com/$AZDO_ORGANIZATION_NAME" project="$AZDO_PROJECT_NAME"
}

#######################################################
# Delete Azure DevOps pipeline if it exists
# Arguments:
#   $1: pipeline_name - Name of the pipeline to delete
# Outputs:
#   Status messages about deletion result
#######################################################
delete_azdo_pipeline_if_exists() {
    local pipeline_name=${1}
    local pipeline_id=$(get_azdo_pipeline_id "${pipeline_name}")

    if [[ -z "${pipeline_id}" || "${pipeline_id}" == "null" ]]; then
        log "No AzDo pipeline with name '${pipeline_name}' found." "info"
    else
        az pipelines delete --id "${pipeline_id}" --yes >/dev/null 2>&1
        log "Deleted existing pipeline '${pipeline_name}' (Pipeline ID: '${pipeline_id}')" "success"
    fi
}

create_azdo_pipeline() {
    local pipeline_name=${1}
    local branch_name=${2}
    local pipeline_description=${3}
    local yaml_path=${4}

    delete_azdo_pipeline_if_exists "${pipeline_name}"
    log "Creating '${pipeline_name}' pipeline from '${branch_name}' branch." "info"

    # Create the Azure DevOps (AzDo) pipeline
    local pipeline_id=$(az pipelines create \
        --name "${pipeline_name}" \
        --description "${pipeline_description}" \
        --repository "${AZDO_REPOSITORY_NAME}" \
        --repository-type tfsgit \
        --branch "${branch_name}" \
        --yaml-path "${yaml_path}" \
        --skip-first-run true \
        --only-show-errors \
        --output json | jq --raw-output '.id')

    log "Pipeline '${pipeline_name}' (Pipeline ID: '${pipeline_id}') created successfully." "success"
    echo "${pipeline_id}"
}

#######################################################
# Create Azure DevOps pipeline variable
# Arguments:
#   $1: pipeline_name - Name of the pipeline
#   $2: variable_name - Name of the variable
# Outputs:
#   Variable creation status
#######################################################
create_azdo_pipeline_variable() {
    local pipeline_name=${1}
    local variable_name=${2}

    # Create the Azure DevOps (AzDo) pipeline variable
    az pipelines variable create \
        --name "${variable_name}" \
        --pipeline-name "${pipeline_name}" \
        --allow-override true \
        --secret false \
        --value "0" \
        --output none

    log "Variable '${variable_name}' created successfully for pipeline '${pipeline_name}'." "success"
}

#######################################################
# Get build policy ID for a repository and branch
# Arguments:
#   $1: repo_id - ID of the repository
#   $2: branch_name - Name of the branch
# Outputs:
#   Build policy ID
#######################################################
get_build_policy_id() {
    local repo_id=${1}
    local branch_name=${2}
    local build_policy_output=$(az repos policy list \
        --repository-id "${repo_id}" \
        --branch "${branch_name}" \
        --query "[?type.displayName=='Build']" \
        --output json)
    local build_policy_id=$(echo "${build_policy_output}" | jq --raw-output '.[0].id')
    echo "${build_policy_id}"
}

#######################################################
# Create Azure DevOps branch policy
# Arguments:
#   $1: repo_name - Name of the repository
#   $2: branch_name - Name of the branch
#   $3: pipeline_name - Name of the pipeline
# Outputs:
#   Branch policy creation/update status
#######################################################
create_azdo_branch_policy() {
    local repo_name=${1}
    local branch_name=${2}
    local pipeline_name=${3}

    local repo_id=$(get_azdo_repo_id "${repo_name}")
    local pipeline_id=$(get_azdo_pipeline_id "${pipeline_name}")
    local build_policy_id=$(get_build_policy_id "${repo_id}" "${branch_name}")

    if [[ -n "${build_policy_id}" && "${build_policy_id}" != "null" ]]; then
        log "Build policy in '${branch_name}' branch for '${pipeline_name}' pipeline already exists, updating it." "info"
        az repos policy build update \
            --id "${build_policy_id}" \
            --blocking true \
            --branch "refs/heads/${branch_name}" \
            --build-definition-id "${pipeline_id}" \
            --display-name "CI QA pipeline" \
            --enabled true \
            --manual-queue-only false \
            --queue-on-source-update-only true \
            --repository-id "${repo_id}" \
            --valid-duration 720 \
            --output none
    else
        log "Creating build policy in '${branch_name}' branch for '${pipeline_name}' pipeline." "info"
        az repos policy build create \
            --blocking true \
            --branch "refs/heads/${branch_name}" \
            --build-definition-id "${pipeline_id}" \
            --display-name "run-${azdo_pipeline_ci_qa}" \
            --enabled true \
            --manual-queue-only false \
            --queue-on-source-update-only true \
            --repository-id "${repo_id}" \
            --valid-duration 720 \
            --output none
    fi
    
    log "Build policy created/updated successfully." "success"
}

# Main execution flow
log "############ CREATING AZDO PIPELINES ############" "info"

set_global_azdo_config
validate_env_vars

create_azdo_pipeline \
    "${azdo_pipeline_ci_qa}" \
    "${AZDO_PIPELINES_BRANCH_NAME}" \
    "This pipeline runs python and Fabric unit tests and linting. It also creates an ephemeral Fabric workspace. Runs on PRs to dev branch." \
    "/devops/azure-pipelines-ci-qa.yml"

create_azdo_pipeline \
    "${azdo_pipeline_ci_qa_cleanup}" \
    "${AZDO_PIPELINES_BRANCH_NAME}" \
    "This pipeline cleans up the ephemeral Fabric workspace created during the QA pipeline run. Adhoc pipeline to be run after PR is closed." \
    "/devops/azure-pipelines-ci-qa-cleanup.yml"

create_azdo_pipeline \
    "${azdo_pipeline_ci_publish_artifacts}" \
    "${AZDO_PIPELINES_BRANCH_NAME}" \
    "This pipeline publishes the build artifacts after the PR is merged to dev/stg/prod branches." \
    "/devops/azure-pipelines-ci-artifacts.yml"

create_azdo_pipeline_variable \
    "${azdo_pipeline_ci_qa_cleanup}" \
    "${azdo_pipeline_variable_pr_id}"

create_azdo_branch_policy \
    "${AZDO_REPOSITORY_NAME}" \
    "${AZDO_POLICIES_BRANCH_NAME}" \
    "${azdo_pipeline_ci_qa}"

log "############ FINISHED AZDO PIPELINES CREATION ############" "success"
