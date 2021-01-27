#!/bin/bash

if [ $# -ne 4 ]; then
    cat << EOF
Usage:

    $0 resourcegroup storageaccount keyvault region

Example:

    $0 resourcegroup storageaccount keyvault eastus2

EOF
    exit 1;
fi

set -e

RESOURCE_GROUP_NAME=$1
TF_STATE_STORAGE_ACCOUNT_NAME=$2
KEYVAULT_NAME=$3
LOCATION=$4

export TF_STATE_CONTAINER_NAME=terraform-state

# Create the resource group
az group create -n $RESOURCE_GROUP_NAME -l $LOCATION

# Create the storage account for dev (hot storage)
az storage account create -g $RESOURCE_GROUP_NAME -l $LOCATION \
  --name "${TF_STATE_STORAGE_ACCOUNT_NAME}dev" \
  --sku Standard_LRS \
  --encryption-services blob \
  --kind StorageV2

# Retrieve the storage account key for dev
ACCOUNT_KEY_DEV=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name "${TF_STATE_STORAGE_ACCOUNT_NAME}dev" --query [0].value -o tsv)

# Create a storage container (for the Terraform State) for dev
az storage container create --name $TF_STATE_CONTAINER_NAME --account-name "${TF_STATE_STORAGE_ACCOUNT_NAME}dev" --account-key $ACCOUNT_KEY_DEV

# Create an Azure KeyVault
az keyvault create -g $RESOURCE_GROUP_NAME -l $LOCATION --name $KEYVAULT_NAME

# Store the Terraform State Storage Key into KeyVault
az keyvault secret set --name tfstate-storage-key-dev --value $ACCOUNT_KEY_DEV --vault-name $KEYVAULT_NAME

# Display information
echo "Run the following command to initialize Terraform to store its state into Azure Storage:"
echo "terraform init -backend-config=\"storage_account_name=$TF_STATE_STORAGE_ACCOUNT_NAME\"dev -backend-config=\"container_name=$TF_STATE_CONTAINER_NAME\" -backend-config=\"access_key=\$(az keyvault secret show --name tfstate-storage-key --vault-name $KEYVAULT_NAME --query value -o tsv)\" -backend-config=\"key=terraform.tfstate\""
