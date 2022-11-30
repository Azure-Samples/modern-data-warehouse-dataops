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

###################
# DEPLOY FOR DEV ENVIRONMENT
env_name="dev"

PROJECT=$project \
DEPLOYMENT_ID=$DEPLOYMENT_ID \
ENV_NAME=$env_name \
AZURE_LOCATION=$AZURE_LOCATION \
AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
bash -c "./scripts/deploy_infrastructure.sh"


print_style "DEPLOYMENT SUCCESSFUL
Details of the deployment can be found in local .env.dev file.\n\n" "success"

echo "See README > Setup and Deployment for more details and next steps." 