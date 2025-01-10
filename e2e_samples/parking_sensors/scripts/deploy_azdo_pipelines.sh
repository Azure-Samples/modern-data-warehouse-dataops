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

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# GITHUB_REPO_URL
# AZDO_PIPELINES_BRANCH_NAME
# DEV_DATAFACTORY_NAME

source ./scripts/common.sh

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

# Release Pipelines
cd_release_pipeline_id=$(create_azdo_pipeline "cd-release" "This pipeline releases across environments")


az pipelines variable create \
    --name devAdfName \
    --pipeline-id "$cd_release_pipeline_id" \
    --value "$DEV_DATAFACTORY_NAME" \
    -o none
