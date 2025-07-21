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

# Set partner ID for telemetry. For usage details, see https://github.com/microsoft/modern-data-warehouse-dataops/blob/main/README.md#data-collection
export AZURE_HTTP_USER_AGENT="acce1e78-babd-6b30-049f-9496f0518a8f"

set -o errexit
set -o pipefail
set -o nounset

. ./scripts/verify_prerequisites.sh
. ./scripts/init_environment.sh
. ./scripts/build_dependencies.sh
. ./scripts/deploy_infrastructure.sh
. ./scripts/configure_unity_catalog.sh
. ./scripts/deploy_azdo_service_connections_github.sh
. ./scripts/deploy_azdo_pipelines.sh

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

build_dependencies

deploy_infrastructure_environment "$ENV_DEPLOY" "$PROJECT"
configure_unity_catalog

# # Create AzDo Github Service Connection -- required only once for the entire deployment
setup_github_service_connection

# # Deploy all pipelines
deploy_azdo_pipelines

## Clean up
remove_dependencies
rm -rf ./scripts/deploystate.env

log "DEPLOYMENT SUCCESSFUL
Details of the deployment can be found in local .env.* files.\n\n" "success"

log "See README > Setup and Deployment for more details and next steps."