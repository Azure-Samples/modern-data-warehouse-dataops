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
# DATABRICKS_HOST
# DATABRICKS_TOKEN - this needs to be a Microsoft Entra ID user token (not PAT token or Microsoft Entra ID application token that belongs to a service principal)
# KEYVAULT_RESOURCE_ID
# KEYVAULT_DNS_NAME
# KEYVAULT_NAME
# USER_NAME
# DATABRICKS_RELEASE_FOLDER
# AZURE_LOCATION

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
databricks workspace mkdirs "$DATABRICKS_RELEASE_FOLDER"
log "$ENV_NAME releases folder: $DATABRICKS_RELEASE_FOLDER"
databricks workspace import "$DATABRICKS_RELEASE_FOLDER/00_setup" --file "./databricks/notebooks/00_setup.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$DATABRICKS_RELEASE_FOLDER/01_explore" --file "./databricks/notebooks/01_explore.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$DATABRICKS_RELEASE_FOLDER/02_standardize" --file "./databricks/notebooks/02_standardize.py" --format SOURCE --language PYTHON --overwrite
databricks workspace import "$DATABRICKS_RELEASE_FOLDER/03_transform" --file "./databricks/notebooks/03_transform.py" --format SOURCE --language PYTHON --overwrite

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

# Find the least resource option that has 4GB memory for each core
least_resource_vm=$(echo "$vm_sizes" | jq --arg common_vms "$common_vms" '
  map(select(.name == ($common_vms | split("\n")[]))) |
  map(select(.memoryInMB >= (.numberOfCores * 4 * 1024))) |
  sort_by( .memoryInMB) |
  .[0]
')

log "VM with the least resources:$least_resource_vm" "info"

# Update the JSON file with the least resource VM
if [ -n "$least_resource_vm" ]; then
    node_type_id=$(echo "$least_resource_vm" | jq -r '.name')
    jq --arg node_type_id "$node_type_id" '.node_type_id = $node_type_id' "$file_path" > tmp.$$.json && mv tmp.$$.json "$file_path"
    log "The JSON file at '$file_path' has been updated with the node_type_id: $node_type_id"
else
    log "No common VM options found between Azure and Databricks." "error"
fi

# Clean up temporary files
rm vm_names.txt

# Create initial cluster, if not yet exists
# cluster.config.json file needs to refer to one of the available SKUs on yout Region
# az vm list-skus --location <LOCATION> --all --output table
cluster_config="./databricks/config/cluster.config.json"
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


# Find the generated .whl file dynamically
WHL_FILE=$(find ./src/ddo_transform/dist/ -name "*.whl" | head -n 1)

if [ -z "$WHL_FILE" ]; then
    log "Error: No .whl file found in dist directory. Make sure the package is built." "error"
    exit 1
fi

WHL_FILENAME=$(basename "$WHL_FILE")

# Upload the dynamically found .whl file to Databricks
log "Uploading $WHL_FILENAME to Databricks DBFS..."
databricks fs cp --recursive --overwrite "$WHL_FILE" "dbfs:/$WHL_FILENAME"
log "Successfully uploaded $WHL_FILENAME to Databricks DBFS." "success"

# Delete the dist folder and WHL file locally
rm -rf ./src/ddo_transform/dist

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
notebook_path="${DATABRICKS_RELEASE_FOLDER}/00_setup"
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
log "Job ID: ${job_id}"

databricks jobs run-now --json "{\"job_id\":$job_id, \"notebook_params\": {\"PYSPARK_PYTHON\": \"/databricks/python3/bin/python3\", \"MOUNT_DATA_PATH\": \"/mnt/datalake\", \"MOUNT_DATA_CONTAINER\": \"datalake\", \"DATABASE\": \"datalake\"}}"
# Upload libs -- for initial dev package
# Needs to run AFTER mounting dbfs:/mnt/datalake in setup workspace

log "Completed configuring databricks." "success"