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

###################
# PARAMETERS

env_name="${1-}"

# Import correct .env file
set -o allexport
env_file=".env.$env_name"
if [[ -e $env_file ]]
then
    source $env_file
fi
set +o allexport

az group delete -g $RESOURCE_GROUP -y --no-wait
az ad sp delete --id $SP_STOR_ID

# az group list --query "[?contains(name,'mdw-dataops-parking')].name" -o tsv | xargs -I % az group delete --name % -y --no-wait


echo "Delete service principal..."
az ad sp list --query "[?contains(appDisplayName,'mdwdo')].appId" -o tsv --show-mine | xargs -I % az ad sp delete --id %
