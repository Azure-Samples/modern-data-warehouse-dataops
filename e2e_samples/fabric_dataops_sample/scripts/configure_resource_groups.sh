#!/bin/bash

# Load the environment variables from the file
source ./../.env

# Ensure a location is provided as a parameter
if [ $# -lt 2 ]; then
  echo "Usage: $0 <location> <security_group_name>"
  exit 1
fi

# Assign the location parameter
location=$1
security_group_name=$2

# Ensure the arrays have the same length
if [ ${#ENVIRONMENT_NAMES[@]} -ne ${#RESOURCE_GROUP_NAMES[@]} ]; then
  echo "[Error] 'ENVIRONMENT_NAMES' and 'RESOURCE_GROUP_NAMES' arrays must have the same length."
  exit 1
fi

# Function to check if a resource group exists
check_resource_group_exists() {
  local resource_group=$1
  az group show --name "$resource_group" &>/dev/null
  return $?  # Returns 0 if exists, 1 otherwise
}

get_security_group_id() {
  local security_group=$1
  security_group_id=$(az ad group show --group "$security_group" --query id -o tsv)
  echo $security_group_id
}

# Function to assign roles to the deployment security group
assign_roles() {
  local resource_group=$1
  local security_group=$2

  subscription_id=$(az account show --query id -o tsv)
  scope="/subscriptions/$subscription_id/resourceGroups/$resource_group"

  echo "[Info] Assigning 'Contributor' role to '$security_group' for '$resource_group'."
  az role assignment create --assignee "$security_group" \
    --role "Contributor" \
    --scope "$scope" \
    --output none

  echo "[Info] Assigning 'Key Vault Purge Operator' role to '$security_group' for '$resource_group'."
  az role assignment create --assignee "$security_group" \
    --role "Key Vault Purge Operator" \
    --scope "$scope" \
    --output none

  echo "[Info] Assigning 'User Access Administrator' role with restricted permissions to '$security_group' for '$resource_group'."
  az role assignment create --assignee "$security_group" \
    --role "User Access Administrator" \
    --scope "$scope" \
    --condition "((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {ba92f5b4-2d11-453d-a403-e96b0029c9fe, b86a8fe4-44ce-4948-aee5-eccb2c155cd7})) AND ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {ba92f5b4-2d11-453d-a403-e96b0029c9fe, b86a8fe4-44ce-4948-aee5-eccb2c155cd7}))" \
    --only-show-errors \
    --output none
}

# Loop through the environments and create the resource groups
for i in "${!ENVIRONMENT_NAMES[@]}"; do
  environment_name=${ENVIRONMENT_NAMES[$i]}
  resource_group_name=${RESOURCE_GROUP_NAMES[$i]}

  echo "############# Processing environment '$environment_name' and resource group '$resource_group_name' #############"

  # Check if the resource group already exists
  if check_resource_group_exists "$resource_group_name"; then
    echo "[Warning] Resource group '$resource_group_name' already exists. Skipping creation."
  else
    echo "[Info] Creating resource group '$resource_group_name' for environment '$environment_name'."

    # Azure CLI command to create the resource group
    az group create \
      --name "$resource_group_name" \
      --location $location \
      --tags Environment="$environment_name" \
      --output none

    # Check if the resource group creation was successful
    if [ $? -eq 0 ]; then
      echo "[Info] Successfully created resource group '$resource_group_name'."
    else
      echo "[Error] Failed to create resource group: '$resource_group_name'."
      exit 1
    fi
  fi

  # Assign roles to the deployment security group
  security_group_id=$(get_security_group_id "$security_group_name")
  if [ -z "$security_group_id" ]; then
    echo "[Error] Security group '$security_group_name' not found."
    exit 1
  else
    echo "[Info] Security group '$security_group_name' found with ID: '$security_group_id'."
    assign_roles "$resource_group_name" "$security_group_id"
  fi

done
