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

# Constants
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

CLUSTER_CONFIG="./config/cluster.config.json"
MOUNT_DATA_PATH="/mnt/datalake"

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
            sleep 2m
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


_main() {
    # Upload notebooks
    echo "Uploading notebooks..."
    databricks workspace import_dir "notebooks" "/notebooks" --overwrite

    # Setup workspace
    echo "Setting up workspace and tables. This may take a while as cluster spins up..."
    wait_for_run $(databricks runs submit --json-file "./config/run.setup.config.json" | jq -r ".run_id" )

    # Create initial cluster, if not yet exists
    echo "Creating an interactive cluster..."
    cluster_name=$(cat $CLUSTER_CONFIG | jq -r ".cluster_name")
    if cluster_exists $cluster_name; then 
        echo "Cluster ${cluster_name} already exists!"
    else
        echo "Creating cluster ${cluster_name}..."
        databricks clusters create --json-file $CLUSTER_CONFIG
    fi

    # Upload dependencies
    echo "Uploading libraries dependencies..."
    databricks fs cp ./libs/ "dbfs:${MOUNT_DATA_PATH}/libs/" --recursive --overwrite

    # Install Library dependencies
    echo "Installing library depedencies..."
    cluster_id=$(databricks clusters list | awk '/'$cluster_name'/ {print $1}')
    databricks libraries install \
        --jar "dbfs:${MOUNT_DATA_PATH}/libs/azure-cosmosdb-spark_2.3.0_2.11-1.2.2-uber.jar" \
        --cluster-id $cluster_id

}

_main


echo "Return to parent script dir: $parent_dir"
cd "$parent_dir"