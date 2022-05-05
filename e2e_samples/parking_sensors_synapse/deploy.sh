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

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

. ./scripts/common.sh
. ./scripts/verify_prerequisites.sh
. ./scripts/init_environment.sh


project=mdwdops # CONSTANT - this is prefixes to all resources of the Parking Sensor sample
github_repo_url="https://github.com/$GITHUB_REPO"


###################
# DEPLOY ALL FOR EACH ENVIRONMENT

for env_name in dev stg prod; do  # dev stg prod
    PROJECT=$project \
    DEPLOYMENT_ID=$DEPLOYMENT_ID \
    ENV_NAME=$env_name \
    AZURE_LOCATION=$AZURE_LOCATION \
    AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
    bash -c "./scripts/deploy_infrastructure.sh"  # inclues AzDevOps Azure Service Connections and Variable Groups
done


###################
# Deploy AzDevOps Pipelines

# Create AzDo Github Service Connection -- required only once for the entire deployment
PROJECT=$project \
GITHUB_PAT_TOKEN=$GITHUB_PAT_TOKEN \
GITHUB_REPO_URL=$github_repo_url \
    bash -c "./scripts/deploy_azdo_service_connections_github.sh"

# This replaces 'your_github_handle/your_repo' to deployer's github project
# Adding "uname" check so that the command works on Mac.
if [[ $(uname) == "Darwin" ]]; then
    sed -i '' "s+your_github_handle/your_repo+$GITHUB_REPO+" devops/azure-pipelines-cd-release.yml
else
    sed -i "s+your_github_handle/your_repo+$GITHUB_REPO+" devops/azure-pipelines-cd-release.yml
fi

# azure-pipelines-cd-release.yml pipeline require DEV_SYNAPSE_WORKSPACE_NAME set, this line retrieves this value from .env.dev file and sets it in DEV_SYNAPSE_WORKSPACE_NAME
declare DEV_"$(grep -e '^SYNAPSE_WORKSPACE_NAME' .env.dev | tail -1 | xargs)"

# Deploy all pipelines
PROJECT=$project \
GITHUB_REPO_URL=$github_repo_url \
AZDO_PIPELINES_BRANCH_NAME=$AZDO_PIPELINES_BRANCH_NAME \
DEV_SYNAPSE_WORKSPACE_NAME=$DEV_SYNAPSE_WORKSPACE_NAME \
    bash -c "./scripts/deploy_azdo_pipelines.sh"

####

print_style "DEPLOYMENT SUCCESSFUL
Details of the deployment can be found in local .env.* files.\n\n" "success"

print_style "IMPORTANT:
This script has updated your local Azure Pipeline YAML definitions to point to your Github repo.
ACTION REQUIRED: Commit and push up these changes to your Github repo before proceeding.\n\n" "warning"

echo "See README > Setup and Deployment for more details and next steps." 