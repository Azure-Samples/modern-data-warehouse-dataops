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

# Check if required utilities are installed
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed. See https://stedolan.github.io/jq/.  Aborting."; exit 1; }
command -v az >/dev/null 2>&1 || { echo >&2 "I require azure cli but it's not installed. See https://bit.ly/2Gc8IsS. Aborting."; exit 1; }

# Check if user is logged in
[[ -n $(az account show 2> /dev/null) ]] || { echo "Please login via the Azure CLI: "; az login; }

# Globals and constants
TIMESTAMP=$(date +%s)
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Set path
dir_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P ); cd "$dir_path"


###################
# USER PARAMETERS

rg_name_pre="${1-}"
rg_location="${2-}"
sub_id="${3-}"

# while [[ -z $env_name ]]; do
#     read -rp "$(echo -e ${ORANGE}"Enter environment (dev, stg or prod): "${NC})" env_name
#     # TODO validate if dev, stg, prod
# done

while [[ -z $rg_name_pre ]]; do
    read -rp "$(echo -e ${ORANGE}"Enter Resource Group name: "${NC})" rg_name_pre
done

while [[ -z $rg_location ]]; do
    read -rp "$(echo -e ${ORANGE}"Enter Azure Location (ei. EAST US 2): "${NC})" rg_location
done

while [[ -z $sub_id ]]; do
    # Check if user only has one sub
    sub_count=$(az account list --output json | jq '. | length')
    if (( $sub_count != 1 )); then
        az account list --output table
        read -rp "$(echo -e ${ORANGE}"Enter Azure Subscription Id you wish to deploy to (enter to use Default): "${NC})" sub_id
    fi
    # If still empty then user selected IsDefault
    if [[ -z $sub_id ]]; then
        sub_id=$(az account show --output json | jq -r '.id')
    fi
done

# By default, set all KeyVault permission to deployer
# Retrieve KeyVault User Id
kvOwnerObjectId=$(az ad signed-in-user show --output json | jq -r '.objectId')


###################
# DEPLOY ALL

for env_name in dev stg prod; do
    # Azure infrastructure
    . ./infrastructure/deploy_infrastructure.sh "$env_name" "$rg_name_pre-$env_name" $rg_location $sub_id $kvOwnerObjectId

    # Databricks
    . ./databricks/create_secrets.sh "$env_name"
    . ./databricks/configure_databricks.sh "$env_name"
done
