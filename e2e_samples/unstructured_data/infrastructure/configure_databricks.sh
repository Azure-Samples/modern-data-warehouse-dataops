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
# AZURE_LOCATION

. ./infrastructure/common.sh

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

databricks_config=$(databricks repos create https://github.com/Azure-Samples/modern-data-warehouse-dataops.git --path /Shared/modern-data-warehouse-dataops)
repo_id=$(echo $databricks_config | jq -r '.id')
databricks repos update $repo_id --branch kraken/unstructured-data-processing

# Define suitable VM for DB cluster
file_path="./infrastructure/cluster.config.json"

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
  sort_by(.numberOfCores, .memoryInMB) |
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
cluster_config="./infrastructure/cluster.config.json"
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

log "Completed configuring databricks." "success"
