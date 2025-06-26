#!/bin/bash

#######################################################
# Deploys Azure DevOps Azure Service Connections
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
# - Correct Azure DevOps Project selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# GITHUB_REPO_URL
# AZDO_PIPELINES_BRANCH_NAME
# DEV_DATAFACTORY_NAME

verify_environment() {
    # azure-pipelines-cd-release.yml pipeline require DEV_DATAFACTORY_NAME set, retrieve this value from .env.dev file
    export DEV_"$(grep -e '^DATAFACTORY_NAME' .env.dev | tail -1 | xargs)"

    # Check if required environment variables are set
    if [[ -z "${PROJECT:-}" || -z "${GITHUB_REPO_URL:-}" || -z "${AZDO_PIPELINES_BRANCH_NAME:-}" || -z "${DEV_DATAFACTORY_NAME:-}" ]]; then
        log "Required environment variables (PROJECT, GITHUB_REPO_URL, AZDO_PIPELINES_BRANCH_NAME, DEV_DATAFACTORY_NAME) are not set." "error"
        exit 1
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log "jq is not installed. Please install jq to proceed." "error"
        exit 1
    fi

    # Retrieve Github Service Connection Id
    github_sc_name="${PROJECT}-github"
    github_sc_id=$(az devops service-endpoint list --output json |
        jq -r --arg NAME "$github_sc_name" '.[] | select(.name==$NAME) | .id')
}

delete_azdo_pipeline_if_exists() {
    declare full_pipeline_name=$1
    
    ## when returning a pipeline that does exist, delete.
    
    pipeline_output=$(az pipelines list --query "[?name=='$full_pipeline_name']" --output json)
    pipeline_id=$(echo "$pipeline_output" | jq -r '.[0].id')
    
    if [[ -n "$pipeline_id" && "$pipeline_id" != "null" ]]; then
        az pipelines delete --id "$pipeline_id" --yes 1>/dev/null
        log "Deleted existing pipeline: $full_pipeline_name (Pipeline ID: $pipeline_id)" "info"
    fi
}

create_azdo_pipeline ()
{
    declare pipeline_name=$1
    declare pipeline_description=$2
    full_pipeline_name=$PROJECT-$pipeline_name

    delete_azdo_pipeline_if_exists "$full_pipeline_name"
    log "Creating deployment pipeline: $full_pipeline_name" "info"

    az pipelines create \
        --name "$full_pipeline_name" \
        --description "$pipeline_description" \
        --repository "$GITHUB_REPO_URL" \
        --branch "$AZDO_PIPELINES_BRANCH_NAME" \
        --yaml-path "/databricks/parking_sensors/devops/azure-pipelines-$pipeline_name.yml" \
        --service-connection "$github_sc_id" \
        --skip-first-run true \
        --output json > /dev/null
}

build_pipelines() {
    #Functions are to be called in separated as cd-release needs the ID to proceed with the next step
    create_azdo_pipeline "ci-qa-python" "This pipeline runs python unit tests and linting."
    create_azdo_pipeline "ci-qa-sql" "This pipeline builds the sql dacpac"
    create_azdo_pipeline "ci-artifacts" "This pipeline publishes build artifacts"
}

release_pipelines() {
    # Release Pipelines - only if it has at least 2 environments
    if [ "$ENV_DEPLOY" -eq 2 ] || [ "$ENV_DEPLOY" -eq 3 ]; then
        log "Release Pipeline are being created - option selected: $ENV_DEPLOY" "info"
        cd_release_pipeline_id=$(create_azdo_pipeline "cd-release" "This pipeline releases across environments")
        az pipelines variable create \
            --name devAdfName \
            --pipeline-id "$cd_release_pipeline_id" \
            --value "$DEV_DATAFACTORY_NAME" \
            --output none
    fi
}

deploy_azdo_pipelines() {
    # Deploy the pipelines
    log "Deploying Azure DevOps Pipelines..." "info"
    verify_environment
    build_pipelines
    release_pipelines
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pushd ..
    . ./scripts/common.sh
    . ./scripts/init_environment.sh
    verify_environment
    build_pipelines
    popd
else
    . ./scripts/common.sh
fi