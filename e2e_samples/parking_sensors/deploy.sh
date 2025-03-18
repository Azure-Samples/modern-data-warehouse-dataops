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

. ./scripts/init_environment.sh
. ./scripts/verify_prerequisites.sh


# CONSTANT - this is prefixes to all resources of the Parking Sensor sample
project=mdwdops 
github_repo_url="https://github.com/$GITHUB_REPO"

#Ask the user the following options:
####
## 1) Only Dev
## 2) Dev and Stage
## 3) All
####

if [ -z "$ENV_DEPLOY" ]; then
    read -r -p "Do you wish to deploy:"$'\n'"  1) Dev Environment Only?"$'\n'"  2) Dev and Stage Environments?"$'\n'"  3) Dev, Stage and Prod (Or Press Enter)?"$'\n'"   Choose 1, 2 or 3: " ENV_DEPLOY
    log "Option Selected: $ENV_DEPLOY" "info"
fi

# Call the deploy function
deploy_infrastructure_environment "$ENV_DEPLOY" "$project"


###################
# Deploy AzDevOps Pipelines
###################

# Create AzDo Github Service Connection -- required only once for the entire deployment
PROJECT=$project \
GITHUB_PAT_TOKEN=$GITHUB_PAT_TOKEN \
GITHUB_REPO_URL=$github_repo_url \
    bash -c "./scripts/deploy_azdo_service_connections_github.sh"

# Replace 'devlace/mdw-dataops-clone' to deployer's github project
sed -i "s+devlace/mdw-dataops-clone+$GITHUB_REPO+" devops/azure-pipelines-cd-release.yml

# azure-pipelines-cd-release.yml pipeline require DEV_DATAFACTORY_NAME set, retrieve this value from .env.dev file
declare DEV_"$(grep -e '^DATAFACTORY_NAME' .env.dev | tail -1 | xargs)"

# Build the WHL package
log "Building the WHL package..."
cd ./src/ddo_transform
# Ensure the dist folder exists
mkdir -p dist
python setup.py bdist_wheel --universal
cd ../..

# Deploy all pipelines
PROJECT=$project \
GITHUB_REPO_URL=$github_repo_url \
AZDO_PIPELINES_BRANCH_NAME=$AZDO_PIPELINES_BRANCH_NAME \
DEV_DATAFACTORY_NAME=$DEV_DATAFACTORY_NAME \
    bash -c "./scripts/deploy_azdo_pipelines.sh"

####

log "DEPLOYMENT SUCCESSFUL
Details of the deployment can be found in local .env.* files.\n\n" "success"

log "See README > Setup and Deployment for more details and next steps." 