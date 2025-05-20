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

. ./scripts/common.sh

delete_azdo_pipeline_if_exists() {
    declare full_pipeline_name=$1
    
    ## when returning a pipeline that does exist, delete.
    
    pipeline_output=$(az pipelines list --query "[?name=='$full_pipeline_name']" --output json)
    pipeline_id=$(echo "$pipeline_output" | jq -r '.[0].id')
    
    if [[ -z "$pipeline_id" || "$pipeline_id" == "null" ]]; then
        log "No Deployment pipeline with name $full_pipeline_name found."
    else
        az pipelines delete --id "$pipeline_id" --yes 1>/dev/null
        log "Deleted existing pipeline: $full_pipeline_name (Pipeline ID: $pipeline_id)"
    fi
}

create_azdo_pipeline ()
{
    declare pipeline_name=$1
    declare pipeline_description=$2
    full_pipeline_name=$PROJECT-$pipeline_name

    delete_azdo_pipeline_if_exists "$full_pipeline_name"
    log "Creating deployment pipeline: $full_pipeline_name"

    pipeline_id=$(az pipelines create \
        --name "$full_pipeline_name" \
        --description "$pipeline_description" \
        --repository "$GITHUB_REPO_URL" \
        --branch "$AZDO_PIPELINES_BRANCH_NAME" \
        --yaml-path "/e2e_samples/parking_sensors/devops/azure-pipelines-$pipeline_name.yml" \
        --service-connection "$github_sc_id" \
        --skip-first-run true \
        --output json | jq -r '.id')
    echo "$pipeline_id"
}


# Retrieve Github Service Connection Id
github_sc_name="${PROJECT}-github"
github_sc_id=$(az devops service-endpoint list --output json |
    jq -r --arg NAME "$github_sc_name" '.[] | select(.name==$NAME) | .id')

##Functions created in the common.sh script


# Build Pipelines
#Functions are to be called in separated as cd-release needs the ID to proceed with the next step

create_azdo_pipeline "ci-qa-python" "This pipeline runs python unit tests and linting."

create_azdo_pipeline "ci-qa-sql" "This pipeline builds the sql dacpac"

create_azdo_pipeline "ci-artifacts" "This pipeline publishes build artifacts"

###################
# Release Pipelines
###################
# Release Pipelines - only if it has at least 2 environments
if [ "$ENV_DEPLOY" -eq 2 ] || [ "$ENV_DEPLOY" -eq 3 ]; then
    log " Release Pipeline are been created - option selected: $ENV_DEPLOY"
    cd_release_pipeline_id=$(create_azdo_pipeline "cd-release" "This pipeline releases across environments")
    az pipelines variable create \
        --name devAdfName \
        --pipeline-id "$cd_release_pipeline_id" \
        --value "$DEV_DATAFACTORY_NAME" \
        --output none
fi