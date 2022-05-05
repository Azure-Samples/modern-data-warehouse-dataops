#!/bin/bash

# Access granted under MIT Open Source License: https://en.wikipedia.org/wiki/MIT_License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, # and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions 
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.


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
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# GITHUB_REPO_URL
# AZDO_PIPELINES_BRANCH_NAME
# DEV_SYNAPSE_WORKSPACE_NAME

# Retrieve Github Service Connection Id
github_sc_name="${PROJECT}-github"
github_sc_id=$(az devops service-endpoint list --output json |
    jq -r --arg NAME "$github_sc_name" '.[] | select(.name==$NAME) | .id')

createPipeline () {
    declare pipeline_name=$1
    declare pipeline_description=$2
    full_pipeline_name=$PROJECT-$pipeline_name

    pipeline_id=$(az pipelines list --query="[?name == '${full_pipeline_name}'].id" -o tsv)
    if [[ -z $pipeline_id ]]; then
        pipeline_id=$(az pipelines create \
            --name "$full_pipeline_name" \
            --description "$pipeline_description" \
            --repository "$GITHUB_REPO_URL" \
            --branch "$AZDO_PIPELINES_BRANCH_NAME" \
            --yaml-path "/e2e_samples/parking_sensors_synapse/devops/azure-pipelines-$pipeline_name.yml" \
            --service-connection "$github_sc_id" \
            --skip-first-run true \
            --query="id" \
            --output tsv )    
    fi    
    echo "$pipeline_id"
}

# Build Pipelines
createPipeline "ci-qa-python" "This pipeline runs python unit tests and linting."
createPipeline "ci-qa-sql" "This pipeline builds the sql dacpac"
createPipeline "ci-artifacts" "This pipeline publishes build artifacts"

# Release Pipelines
cd_release_pipeline_id=$(createPipeline "cd-release" "This pipeline releases across environments")


if [[ -z $(az pipelines variable list --pipeline-id "${cd_release_pipeline_id}" --query "devSynapseWorkspaceName" -o tsv) ]]; then
    az pipelines variable create \
        --name devSynapseWorkspaceName \
        --pipeline-id "$cd_release_pipeline_id" \
        --value "$DEV_SYNAPSE_WORKSPACE_NAME"
else
    echo "Pipeline variable already exists. devSynapseWorkspaceName"
fi