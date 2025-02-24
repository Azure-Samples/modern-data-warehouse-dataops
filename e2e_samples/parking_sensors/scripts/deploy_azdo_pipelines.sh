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
        -o none
fi