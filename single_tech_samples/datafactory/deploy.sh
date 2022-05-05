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

. ./scripts/common.sh
. ./scripts/verify_prerequisites.sh
. ./scripts/init_environment.sh

###################
# DEPLOY ALL RESOURCES FOR EACH ENVIRONMENT

for env_name in dev stg prod; do  # dev stg prod
    export ENV_NAME=$env_name
    export RESOURCE_GROUP_NAME="$RESOURCE_GROUP_NAME_PREFIX-$env_name-rg"
    export GITHUB_REPO_URL="https://github.com/$GITHUB_REPO"
    ./scripts/deploy_infrastructure.sh  # inclues AzDevOps Azure Service Connections and Variable Groups
done

###################
# Deploy AzDevOps Pipelines

# AzDo Github Service Connection -- required only once for the entire deployment
./scripts/deploy_azdo_service_connections_github.sh

# Release pipelines require DEV_DATAFACTORY_NAME set, retrieve this value from .env.dev file
export DEV_$(egrep '^DATAFACTORY_NAME' .env.dev | tail -1 | xargs)

# Replace 'githubuser/mdw-dataops-clone' to deployer's github project
sed -i "s+githubuser/mdw-dataops-clone+$GITHUB_REPO+" devops/azure-pipelines-cd-release.yml

# Deploy pipelines
./scripts/deploy_azdo_pipelines.sh