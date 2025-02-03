#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# AZDO_ORGANIZATION_NAME
# AZDO_PROJECT_NAME
# AZDO_REPOSITORY_NAME
# AZDO_BRANCH_NAME
###################

# Function to validate required environment variables
validate_env_vars() {
  local missing_vars=()

  for var in AZDO_ORGANIZATION_NAME AZDO_PROJECT_NAME AZDO_REPOSITORY_NAME AZDO_BRANCH_NAME; do
    if [[ -z "${!var}" ]]; then
      missing_vars+=("$var")
    fi
  done

  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "[Error] The following environment variables are missing:"
    for var in "${missing_vars[@]}"; do
      echo "  - $var"
    done
    exit 1
  fi
}

set_global_azdo_config() {
  # Set the global Azure DevOps (AzDo) configuration
  az devops configure --defaults organization="https://dev.azure.com/$AZDO_ORGANIZATION_NAME" project="$AZDO_PROJECT_NAME"
}

delete_azdo_pipeline_if_exists() {
  pipeline_name=$1
  pipeline_output=$(az pipelines list --query "[?name=='$pipeline_name']" --output json)
  pipeline_id=$(echo "$pipeline_output" | jq -r '.[0].id')

  if [[ -z "$pipeline_id" || "$pipeline_id" == "null" ]]; then
    echo "[Info] No AzDo pipeline with name '$pipeline_name' found."
  else
    az pipelines delete --id "$pipeline_id" --yes 1>/dev/null
    echo "[Info] Deleted existing pipeline '$pipeline_name' (Pipeline ID: '$pipeline_id')"
  fi
}

create_azdo_pipeline() {
  pipeline_name=$1
  pipeline_description=$2
  yaml_path=$3

  delete_azdo_pipeline_if_exists "$pipeline_name"
  echo "[Info] Creating '$pipeline_name' pipeline."

  # Create the Azure DevOps (AzDo) pipeline
  pipeline_id=$(az pipelines create \
    --name "$pipeline_name" \
    --description "$pipeline_description" \
    --repository "$AZDO_REPOSITORY_NAME" \
    --repository-type tfsgit \
    --branch "$AZDO_BRANCH_NAME" \
    --yaml-path "$yaml_path" \
    --skip-first-run true \
    --only-show-errors \
    --output json |
    jq -r '.id')

  echo "[Info] Pipeline '$pipeline_name' (Pipeline ID: '$pipeline_id') created successfully."
}

validate_env_vars

echo "[Info] ############ CREATING AZDO PIPELINES  ############"
set_global_azdo_config

create_azdo_pipeline \
  "pl-ci-qa" \
  "This pipeline runs python and Fabric unit tests and linting. It also creates an ephemeral Fabric workspace. Runs on PRs to dev branch." \
  "/devops/azure-pipelines-ci-qa.yml"

create_azdo_pipeline \
  "pl-ci-qa-cleanup" \
  "This pipeline cleans up the ephemeral Fabric workspace created during the QA pipeline run. Adhoc pipeline to be run after PR is closed." \
  "/devops/azure-pipelines-ci-qa-cleanup.yml"

create_azdo_pipeline \
  "pl-ci-publish-artifacts" \
  "This pipeline publishes the build artifacts after the PR is merged to dev/stg/prod branches." \
  "/devops/azure-pipelines-ci-artifacts.yml"

echo "[Info] ############ FINISHED AZDO PIPELINES CREATION ############"
