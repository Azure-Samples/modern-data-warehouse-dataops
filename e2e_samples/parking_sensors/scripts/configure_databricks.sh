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

# REQUIRED VARIABLES:
#
# DATABRICKS_HOST
# DATABRICKS_TOKEN - this needs to be a Microsoft Entra ID user token (not PAT token or Microsoft Entra ID application token that belongs to a service principal)
# KEYVAULT_RESOURCE_ID
# KEYVAULT_DNS_NAME
# USER_NAME

. ./scripts/common.sh

log "Configuring Databricks workspace."

# Create secret scope, if not exists
scope_name="storage_scope"
if [[ ! -z $(databricks secrets list-scopes | grep "$scope_name") ]]; then
    # Delete existing scope
    # NOTE: Need to recreate everytime to ensure idempotent deployment. Reruning deployment overrides KeyVault permissions.
    log "Scope already exists, re-creating secrets scope: $scope_name"
    databricks secrets delete-scope "$scope_name"
fi

# Create secret scope
databricks secrets create-scope --json "{\"scope\": \"$scope_name\", \"scope_backend_type\": \"AZURE_KEYVAULT\", \"backend_azure_keyvault\": { \"resource_id\": \"$KEYVAULT_RESOURCE_ID\", \"dns_name\": \"$KEYVAULT_DNS_NAME\" } }"

# Upload notebooks
log "Uploading notebooks..."
databricks_folder_name="/Workspace/Users/${USER_NAME,,}"
log "databricks_folder_name: ${databricks_folder_name}"

databricks workspace import "$databricks_folder_name/00_setup.py" --file "./databricks/notebooks/00_setup.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$databricks_folder_name/01_explore.py" --file "./databricks/notebooks/01_explore.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$databricks_folder_name/02_standardize.py" --file "./databricks/notebooks/02_standardize.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$databricks_folder_name/03_transform.py" --file "./databricks/notebooks/03_transform.py" --format SOURCE --language PYTHON --overwrite

# Create initial cluster, if not yet exists
# cluster.config.json file needs to refer to one of the available SKUs on yout Region
# az vm list-skus --location <LOCATION> --all --output table
cluster_config="./databricks/config/cluster.config.json"
log "Creating an interactive cluster using config in $cluster_config..."
cluster_name=$(cat "$cluster_config" | jq -r ".cluster_name")
if databricks_cluster_exists "$cluster_name"; then 
    log "Cluster ${cluster_name} already exists! Skipping creation..." "info"
else
    log "Creating cluster ${cluster_name}..."
    databricks clusters create --json "@$cluster_config"
fi

cluster_id=$(databricks clusters list --output JSON | jq -r '.[]|select(.default_tags.ClusterName == "ddo_cluster")|.cluster_id')
log "Cluster ID:" $cluster_id

adfTempDir=.tmp/adf
mkdir -p $adfTempDir && cp -a adf/ .tmp/
tmpfile=.tmpfile
adfLsDir=$adfTempDir/linkedService
jq --arg databricksExistingClusterId "$cluster_id" '.properties.typeProperties.existingClusterId = $databricksExistingClusterId' $adfLsDir/Ls_AzureDatabricks_01.json > "$tmpfile" && mv "$tmpfile" $adfLsDir/Ls_AzureDatabricks_01.json

log "Uploading libs TO dbfs..."
databricks fs cp --recursive --overwrite "./databricks/libs/ddo_transform-localdev-py2.py3-none-any.whl" "dbfs:/ddo_transform-localdev-py2.py3-none-any.whl"

# Create JSON file for library installation
json_file="./databricks/config/libs.config.json"
cat <<EOF > $json_file
{
  "cluster_id": "$cluster_id",
  "libraries": [
    {
      "whl": "dbfs:/ddo_transform-localdev-py2.py3-none-any.whl"
    }
  ]
}
EOF

# Install library on the cluster using the JSON file
databricks libraries install --json @$json_file

# Creates a Job to setup workspace
log "Creating a job to setup the workspace..."
notebook_path="${databricks_folder_name}/00_setup.py"
log "notebook_path: ${notebook_path}"
json_file_config="./databricks/config/job.setup.config.json"
cat <<EOF > $json_file_config
{
  "name": "databricks_job_setup",
  "timeout_seconds": 3600,
  "max_concurrent_runs": 1,
  "tasks": [{
      "task_key": "run-setup-nb",
      "run_if": "ALL_SUCCESS",
      "notebook_task": {
        "notebook_path": "$notebook_path",
        "source": "WORKSPACE"
    },
    "existing_cluster_id": "$cluster_id"
    }]  
}
EOF

job_id=$(databricks jobs create --json @$json_file_config | jq -r ".job_id")
log "Job ID:" $job_id

databricks jobs run-now --json "{\"job_id\":$job_id, \"notebook_params\": {\"PYSPARK_PYTHON\": \"/databricks/python3/bin/python3\", \"MOUNT_DATA_PATH\": \"/mnt/datalake\", \"MOUNT_DATA_CONTAINER\": \"datalake\", \"DATABASE\": \"datalake\"}}"
# Upload libs -- for initial dev package
# Needs to run AFTER mounting dbfs:/mnt/datalake in setup workspace

log "Completed configuring databricks." "success"