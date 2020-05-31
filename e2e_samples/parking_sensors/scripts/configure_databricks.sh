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

# REQUIRED VARIABLES:
#
# DATABRICKS_HOST
# DATABRICKS_TOKEN
# AZURE_STORAGE_ACCOUNT
# APPINSIGHTS_KEY
# SP_STOR_ID
# SP_STOR_PASS
# SP_STOR_TENANT


wait_for_run () {
    # See here: https://docs.azuredatabricks.net/api/latest/jobs.html#jobsrunresultstate
    declare mount_run_id=$1
    while : ; do
        life_cycle_status=$(databricks runs get --run-id $mount_run_id | jq -r ".state.life_cycle_state") 
        result_state=$(databricks runs get --run-id $mount_run_id | jq -r ".state.result_state")
        if [[ $result_state == "SUCCESS" || $result_state == "SKIPPED" ]]; then
            break;
        elif [[ $life_cycle_status == "INTERNAL_ERROR" || $result_state == "FAILED" ]]; then
            state_message=$(databricks runs get --run-id $mount_run_id | jq -r ".state.state_message")
            echo -e "${RED}Error while running ${mount_run_id}: ${state_message} ${NC}"
            exit 1
        else 
            echo "Waiting for run ${mount_run_id} to finish..."
            sleep 1m
        fi
    done
}


cluster_exists () {
    declare cluster_name="$1"
    declare cluster=$(databricks clusters list | tr -s " " | cut -d" " -f2 | grep ^${cluster_name}$)
    if [[ -n $cluster ]]; then
        return 0; # cluster exists
    else
        return 1; # cluster does not exists
    fi
}

echo "Configuring Databricks workspace."

# Create secret scope, if not exists
scope_name="storage_scope"
if [[ -z $(databricks secrets list-scopes | grep "$scope_name") ]]; then
    echo "Creating secrets scope: $scope_name"
    databricks secrets create-scope --scope "$scope_name"
fi

# Create secrets
echo "Creating secrets within scope $scope_name..."

databricks secrets write --scope "$scope_name" --key "appinsights_key" --string-value  "$APPINSIGHTS_KEY"
databricks secrets write --scope "$scope_name" --key "storage_account" --string-value  "$AZURE_STORAGE_ACCOUNT"
databricks secrets write --scope "$scope_name" --key "storage_sp_id" --string-value  "$SP_STOR_ID"
databricks secrets write --scope "$scope_name" --key "storage_sp_key" --string-value  "$SP_STOR_PASS"
databricks secrets write --scope "$scope_name" --key "storage_sp_tenant" --string-value  "$SP_STOR_TENANT"

# Upload notebooks
echo "Uploading notebooks..."
databricks workspace import_dir "./databricks/notebooks" "/notebooks" --overwrite

# Setup workspace
echo "Setting up workspace and tables. This may take a while as cluster spins up..."
wait_for_run $(databricks runs submit --json-file "./databricks/config/run.setup.config.json" | jq -r ".run_id" )

# Upload libs -- for initial dev package
# Needs to run AFTER mounting dbfs:/mnt/datalake in setup workspace
echo "Uploading libs..."
databricks fs cp --recursive --overwrite "./databricks/libs/" "dbfs:/mnt/datalake/sys/databricks/libs/"

# Create initial cluster, if not yet exists
cluster_config="./databricks/config/cluster.config.json"
echo "Creating an interactive cluster using config in $cluster_config..."
cluster_name=$(cat $cluster_config | jq -r ".cluster_name")
if cluster_exists $cluster_name; then 
    echo "Cluster ${cluster_name} already exists!"
else
    echo "Creating cluster ${cluster_name}..."
    databricks clusters create --json-file $cluster_config
fi

echo "Completed configuring databricks."