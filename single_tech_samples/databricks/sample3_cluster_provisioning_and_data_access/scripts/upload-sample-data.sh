#!/usr/bin/env bash

set -e

DEPLOYMENT_PREFIX=${DEPLOYMENT_PREFIX:-}
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
AZURE_RESOURCE_GROUP_NAME=${AZURE_RESOURCE_GROUP_NAME:-}
AZURE_RESOURCE_GROUP_LOCATION=${AZURE_RESOURCE_GROUP_LOCATION:-}

if [[ -z "$DEPLOYMENT_PREFIX" ]]; then
    echo "No deployment prefix [DEPLOYMENT_PREFIX] specified."
    exit 1
fi
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified."
    exit 1
fi
if [[ -z "$AZURE_RESOURCE_GROUP_NAME" ]]; then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_NAME] specified."
    exit 1
fi
if [[ -z "$AZURE_RESOURCE_GROUP_LOCATION" ]]; then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_LOCATION] specified."
    echo "Default location will be set to -> westus"
    AZURE_RESOURCE_GROUP_LOCATION="westus"
fi

# Variables

storageAccountName="${DEPLOYMENT_PREFIX}asa01"
storageAccountContainerName="sample-container"
sampleDataFile="sample-data.us-population.json"

# Create a storage container for file uploads
storageKeys=$(az storage account keys list --resource-group "$AZURE_RESOURCE_GROUP_NAME" --account-name "$storageAccountName" --output json)
storageAccountKey=$(echo "$storageKeys" | jq -r '.[0].value')
containerExists=$(az storage container exists --account-name "$storageAccountName" --account-key "$storageAccountKey" --name "$storageAccountContainerName" --output json | jq -r '.exists')
if [[ "$containerExists" == "false" ]]; then
    echo "Container $storageAccountContainerName does not existing and will be created."
    az storage container create --account-name "$storageAccountName" --account-key "$storageAccountKey" --name "$storageAccountContainerName" --output none
fi
echo "Uploading file ./$sampleDataFile"
az storage blob upload --account-name "$storageAccountName" --account-key "$storageAccountKey" --container-name "$storageAccountContainerName" \
    --file "./$sampleDataFile" --name "$sampleDataFile" --output none

# Assign Storage Blob Data Contributor role to the current account
storageAccountID=$(az storage account show --name "$storageAccountName" --query id --output tsv)
assignee=$(az account show --query user.name --output tsv)
az role assignment create --assignee "$assignee" --role "Storage Blob Data Contributor" --scope "$storageAccountID" --output none
