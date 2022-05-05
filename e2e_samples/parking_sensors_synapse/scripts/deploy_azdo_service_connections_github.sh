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
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# GITHUB_PAT_TOKEN
# GITHUB_REPO_URL

###############
# Setup Github service connection

github_sc_name="${PROJECT}-github"
export AZURE_DEVOPS_EXT_GITHUB_PAT=$GITHUB_PAT_TOKEN

if sc_id=$(az devops service-endpoint list -o tsv | grep "$github_sc_name" | awk '{print $3}'); then
    echo "Service connection: $github_sc_name already exists. Deleting..."
    az devops service-endpoint delete --id "$sc_id" -y
fi
echo "Creating Github service connection: $github_sc_name in Azure DevOps"
github_sc_id=$(az devops service-endpoint github create \
    --name "$github_sc_name" \
    --github-url "$GITHUB_REPO_URL" \
    --output json |
    jq -r '.id')

az devops service-endpoint update \
    --id "$github_sc_id" \
    --enable-for-all "true"