#!/bin/bash

#######################################################
# Deploys Azure DevOps Github Service Connections
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
# GITHUB_PAT_TOKEN
# GITHUB_REPO_URL

. ./scripts/common.sh

###############
# Setup Github service connection

github_sc_name="${PROJECT}-github"
export AZURE_DEVOPS_EXT_GITHUB_PAT=$GITHUB_PAT_TOKEN

if sc_id=$(az devops service-endpoint list --output json | jq -r -e --arg sc_name "$github_sc_name" '.[] | select(.name==$sc_name) | .id'); then
    log "Service connection: $github_sc_name already exists. Deleting service connection id $sc_id ..." "info"
    az devops service-endpoint delete --id "$sc_id" -y  --output none
fi

log "Creating Github service connection: $github_sc_name in Azure DevOps"
github_sc_id=$(az devops service-endpoint github create \
    --name "$github_sc_name" \
    --github-url "$GITHUB_REPO_URL" \
    --output json |
    jq -r '.id')

az devops service-endpoint update \
    --id "$github_sc_id" \
    --enable-for-all "true" \
     --output none