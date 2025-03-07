#!/bin/bash

#######################################################
# Configures Azure Databricks cluster and workspace
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
# - Correct Azure DevOps Project selected
#
# Called from: e2e_samples/parking_sensors/scripts/deploy.sh
# - Creates a new cluster and deploys a sample python library
# - Stores the cluster ID in KeyVault
# - Deploys sample python notebooks to the Databricks workspace
#######################################################

set -o errexit
set -o pipefail
set -o nounset

# REQUIRED VARIABLES:
#
# AZURE_SUBSCRIPTION_ID
# RESOURCE_GROUP_NAME
# STORAGE_ACCOUNT_NAME
# ENVIRONMENT_NAME
# DATABRICKS_HOST
# DATABRICKS_TOKEN - this needs to be a Microsoft Entra ID user token (not PAT token or Microsoft Entra ID application token that belongs to a service principal)
# DATABRICKS_KV_TOKEN
# KEYVAULT_RESOURCE_ID
# KEYVAULT_DNS_NAME
# KEYVAULT_NAME
# USER_NAME
# DATABRICKS_RELEASE_FOLDER
# AZURE_LOCATION
# PROJECT
# DEPLOYMENT_ID

. ./scripts/common.sh


data_stg_account_name="${PROJECT}st${ENVIRONMENT_NAME}${DEPLOYMENT_ID}"
resource_group_name="${PROJECT}-${DEPLOYMENT_ID}-${ENVIRONMENT_NAME}-rg"

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
databricks workspace mkdirs "$DATABRICKS_RELEASE_FOLDER"
log "$ENVIRONMENT_NAME releases folder: $DATABRICKS_RELEASE_FOLDER"
databricks workspace mkdirs "$DATABRICKS_RELEASE_FOLDER/notebooks"
log "$ENVIRONMENT_NAME notebooks folder: $DATABRICKS_RELEASE_FOLDER/notebooks"	
databricks workspace import "$DATABRICKS_RELEASE_FOLDER/notebooks/00_setup" --file "./databricks/notebooks/00_setup.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$DATABRICKS_RELEASE_FOLDER/notebooks/01_explore" --file "./databricks/notebooks/01_explore.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$DATABRICKS_RELEASE_FOLDER/notebooks/02_standardize" --file "./databricks/notebooks/02_standardize.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$DATABRICKS_RELEASE_FOLDER/notebooks/03_transform" --file "./databricks/notebooks/03_transform.py" --format SOURCE --language PYTHON --overwrite

# Define suitable VM for DB cluster
file_path="./databricks/config/cluster.config.json"

# Get available VM sizes in the specified region
vm_sizes=$(az vm list-sizes --location "$AZURE_LOCATION" --output json)

# Get available Databricks node types using the list-node-types API
node_types=$(databricks clusters list-node-types --output json)

# Extract VM names and node type IDs into temporary files
echo "$vm_sizes" | jq -r '.[] | .name' > vm_names.txt
# Get available Databricks node types using the list-node-types API and filter node types to only include those that support Photon
photon_node_types=$(echo "$node_types" | jq -r '.node_types[] | select(.photon_driver_capable == true) | .node_type_id')

# Find common VM sizes
common_vms=$(grep -Fwf <(echo "$photon_node_types") vm_names.txt)

# Find the VM with the least resources
least_resource_vm=$(echo "$vm_sizes" | jq --arg common_vms "$common_vms" '
  map(select(.name == ($common_vms | split("\n")[]))) |
  # Photon clusters in some regions may require 4GB per core of memory. Uncomment the next line if required.
  # map(select(.memoryInMB >= (.numberOfCores * 4 * 1024))) |
  sort_by( .memoryInMB) |
  .[0]
')

log "VM with the least resources:$least_resource_vm" "info"

# Update the JSON file with the least resource VM
if [ -n "$least_resource_vm" ]; then
    node_type_id=$(echo "$least_resource_vm" | jq -r '.name')
else
    log "No common VM options found between Azure and Databricks." "error"
fi

# Clean up temporary files
rm vm_names.txt

# Create initial cluster, if not yet exists
catalog_name="${PROJECT}-${DEPLOYMENT_ID}-catalog-${ENVIRONMENT_NAME}"
cluster_config="./databricks/config/cluster.config.json"
cat <<EOF > $cluster_config

{
  "cluster_name": "ddo_cluster",
  "autoscale": {
    "min_workers": 1,
    "max_workers": 2
  },
  "spark_version": "14.3.x-scala2.12",
  "autotermination_minutes": 30,
  "node_type_id": "$node_type_id",
  "data_security_mode": "USER_ISOLATION",
  "runtime_engine": "PHOTON",
  "spark_env_vars": {
    "PYSPARK_PYTHON": "/databricks/python3/bin/python3",
    "DATABASE": "datalake"
  },
  "spark_conf": {
    "spark.sql.catalog.$catalog_name": "com.databricks.sql.catalog"
  }
}
EOF

log "Creating an interactive cluster using config in $cluster_config..."
cluster_name=$(cat "$cluster_config" | jq -r ".cluster_name")
if databricks_cluster_exists "$cluster_name"; then 
    log "Cluster ${cluster_name} already exists! Skipping creation..." "info"
else
    log "Creating cluster ${cluster_name}..." "info"
    databricks clusters create --json "@$cluster_config"
fi

cluster_id=$(databricks clusters list --output JSON | jq -r '.[]|select(.cluster_name == "ddo_cluster")|.cluster_id')
if [ -z "$cluster_id" ]; then
    log "Failed to retrieve cluster ID or cluster does not exist." "error"
    exit
else
    log "Cluster ID: $cluster_id" "info"
fi

az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "databricksClusterId" --value "$cluster_id" -o none


log "Uploading libs TO libraries folder..."

libs_path="$DATABRICKS_RELEASE_FOLDER/libs"

databricks workspace mkdirs "$libs_path"
databricks workspace import --language PYTHON --format AUTO --overwrite --file "./databricks/libs/ddo_transform-localdev-py2.py3-none-any.whl" "/Workspace/$libs_path/ddo_transform-localdev-py2.py3-none-any.whl"

# Create JSON file for library installation
json_file="./databricks/config/libs.config.json"
cat <<EOF > $json_file
{
  "cluster_id": "$cluster_id",
  "libraries": [
    {
      "whl": "/Workspace/releases/dev/libs/ddo_transform-localdev-py2.py3-none-any.whl"
    }
  ]
}
EOF

# Install library on the cluster using the JSON file
databricks libraries install --json @$json_file

# Creates a Job to setup workspace
log "Creating a job to setup the workspace..."
notebook_path="${DATABRICKS_RELEASE_FOLDER}/notebooks/00_setup"
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
        "source": "WORKSPACE",
        "base_parameters": {
          "catalogname": "$catalog_name",
          "stgaccountname": "$data_stg_account_name"
        }
      },
    "existing_cluster_id": "$cluster_id"
    }]  
}
EOF

databricks catalogs list 
if [ -n "$catalog_name" ]; then
  if [ -z "$(databricks catalogs list | grep -w "$catalog_name")" ]; then
      log "Catalog '$catalog_name' does not exist. It should exist..." "danger"
      exit 1
  fi
else 
  log "Catalog name is empty. It should exist." "danger"
  exit 1
fi

job_id=$(databricks jobs create --json @$json_file_config | jq -r ".job_id")
log "Job ID: ${job_id}"

databricks jobs run-now --json "{\"job_id\":$job_id, \"notebook_params\": {\"PYSPARK_PYTHON\": \"/databricks/python3/bin/python3\", \"DATABASE\": \"datalake\" }}"
log "Completed configuring databricks." "success"