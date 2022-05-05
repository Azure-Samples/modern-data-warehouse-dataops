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
set -o xtrace # For debugging

# !! WARNING: !!
## THIS SCRIPT WILL DELETE RESOURCES PREFIXED WITH mdwdo-adf !!


###################
# PARAMETERS
#
# RESOURCE_GROUP_NAME_PREFIX

prefix="mdwdo"
RESOURCE_GROUP_NAME_PREFIX="mdwdo-adf"

echo "Delete pipelines the start with '$prefix' in name..."
[[ ! -z $prefix ]] &&
    az pipelines list -o tsv |
    grep "$prefix" |
    awk '{print $4}' |
    xargs -r -I % az pipelines delete --id % --yes

echo "Delete variable groups the start with '$prefix' in name..."
[[ ! -z $prefix ]] &&
    az pipelines variable-group list -o tsv |
    grep "$prefix" |
    awk '{print $3}' |
    xargs -r -I % az pipelines variable-group delete --id % --yes

echo "Delete service connections the start with '$prefix' in name..."
[[ ! -z $prefix ]] &&
    az devops service-endpoint list -o tsv |
    grep "$prefix" |
    awk '{print $3}' |
    xargs -r -I % az devops service-endpoint delete --id % --yes

echo "Delete service principal the start with '$prefix' in name, created by yourself..."
[[ ! -z $prefix ]] &&
    az ad sp list --query "[?contains(appDisplayName,'$prefix')].appId" -o tsv --show-mine |
    xargs -r -I % az ad sp delete --id %

echo "Delete resource group the start with '$RESOURCE_GROUP_NAME_PREFIX' in name..."
[[ ! -z $RESOURCE_GROUP_NAME_PREFIX ]] &&
    az group list --query "[?contains(name,'$RESOURCE_GROUP_NAME_PREFIX')].name" -o tsv |
    xargs -I % az group delete --verbose --name % -y
