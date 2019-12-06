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

# Set path
parent_dir=$(pwd -P)
dir_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P ); cd "$dir_path"

# Set constants
scope_name="storage_scope" # fixed # TODO pass via arm template

###################
# Requires the following to be set:
#
# BLOB_STORAGE_ACCOUNT=
# SP_STOR_ID=
# SP_STOR_PASS=
# SP_STOR_TENANT=


###################
# USER PARAMETERS
env_name="${1-}"

# Import correct .env file
set -o allexport
env_file="../.env.$env_name"
if [[ -e $env_file ]]
then
    source $env_file
fi
set +o allexport

# Create scope, if not exists
if [[ -z $(databricks secrets list-scopes | grep "$scope_name") ]]; then
    echo "Creating secrets scope: $scope_name"
    databricks secrets create-scope --scope "$scope_name"
fi

# Create secrets
echo "Creating secrets within scope $scope_name..."

databricks secrets write --scope "$scope_name" --key "storage_account" --string-value  "$BLOB_STORAGE_ACCOUNT"
databricks secrets write --scope "$scope_name" --key "storage_sp_id" --string-value  "$SP_STOR_ID"
databricks secrets write --scope "$scope_name" --key "storage_sp_key" --string-value  "$SP_STOR_PASS"
databricks secrets write --scope "$scope_name" --key "storage_sp_tenant" --string-value  "$SP_STOR_TENANT"


echo "Return to parent script dir: $parent_dir"
cd "$parent_dir"