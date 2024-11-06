#!/bin/bash

if [[ -z $1 ]];
then 
    echo "No parameter passed. Please provide a suffix to guarantee uniqueness of resource names"
    exit
fi

SUFFIX=$1
RG_NAME=data-share-automation
LOCATION=westeurope
SOURCE_STORAGE_ACCOUNT_NAME=sourcestorage$SUFFIX
DEST_STORAGE_ACCOUNT_NAME=deststorage$SUFFIX
SOURCE_DATA_SHARE_ACCOUNT_NAME=source-data-share$SUFFIX
DEST_DATA_SHARE_ACCOUNT_NAME=dest-data-share$SUFFIX
CONTAINER_NAME=share-data

echo "Getting subscription Id..."
SUBSCRIPTION_ID=$(az account show -o tsv --query [id] | tr -d '\r')
echo "Creating resources on subscription $SUBSCRIPTION_ID"
echo "Creating resource group '$RG_NAME'"
az group create -l $LOCATION -g $RG_NAME -o none
echo "Creating source storage account '$SOURCE_STORAGE_ACCOUNT_NAME'"
az storage account create -l $LOCATION -g $RG_NAME -n $SOURCE_STORAGE_ACCOUNT_NAME --hns True --kind StorageV2 -o none
echo "Creating destination storage account '$DEST_STORAGE_ACCOUNT_NAME'"
az storage account create -l $LOCATION -g $RG_NAME -n $DEST_STORAGE_ACCOUNT_NAME --hns True --kind StorageV2 -o none
echo "Creating source data share account '$SOURCE_DATA_SHARE_ACCOUNT_NAME'"
az datashare account create -l $LOCATION -g $RG_NAME -n $SOURCE_DATA_SHARE_ACCOUNT_NAME -o none --only-show-errors
echo "Creating destination data share account '$DEST_DATA_SHARE_ACCOUNT_NAME'"
az datashare account create -l $LOCATION -g $RG_NAME -n $DEST_DATA_SHARE_ACCOUNT_NAME -o none --only-show-errors

echo "Adding MSI of $SOURCE_DATA_SHARE_ACCOUNT_NAME to 'Storage Blob Data Reader' on $SOURCE_STORAGE_ACCOUNT_NAME"
SOURCE_MSI=$(az datashare account show -g $RG_NAME --name $SOURCE_DATA_SHARE_ACCOUNT_NAME -o tsv --query [identity.principalId] --only-show-errors | tr -d '\r')
az role assignment create --role "Storage Blob Data Reader" \
--assignee $SOURCE_MSI \
--scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$SOURCE_STORAGE_ACCOUNT_NAME" \
--output none

echo "Adding MSI of $DEST_DATA_SHARE_ACCOUNT_NAME to 'Storage Blob Data Contributor' on $DEST_STORAGE_ACCOUNT_NAME"
DEST_MSI=$(az datashare account show -g $RG_NAME --name $DEST_DATA_SHARE_ACCOUNT_NAME -o tsv --query [identity.principalId] --only-show-errors | tr -d '\r')
az role assignment create --role "Storage Blob Data Contributor" \
--assignee $DEST_MSI \
--scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$DEST_STORAGE_ACCOUNT_NAME" \
--output none

echo "Retrieving storage key to upload sample data..."
KEY=$(az storage account keys list -g $RG_NAME -n $SOURCE_STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

echo "Creating container '$CONTAINER_NAME' in '$SOURCE_STORAGE_ACCOUNT_NAME'"
az storage container create --account-name $SOURCE_STORAGE_ACCOUNT_NAME --account-key $KEY -n $CONTAINER_NAME -o none
echo "Uploading data..."
az storage blob upload --account-name $SOURCE_STORAGE_ACCOUNT_NAME --account-key $KEY --container $CONTAINER_NAME -f Readme.md --overwrite -o none --only-show-errors
echo "All Done!"