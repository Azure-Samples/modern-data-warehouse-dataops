#!/bin/bash

[ "$#" -eq 2 ] || { echo "Usage: ./bash_setup_permissions.sh <suffix> <objectId>"; exit; }

SUFFIX=$1
SP_ID=$2
RG_NAME=data-share-automation
DEST_STORAGE_ACCOUNT_NAME=deststorage$SUFFIX
DEST_DATA_SHARE_ACCOUNT_NAME=dest-data-share$SUFFIX

echo "Getting subscription Id..."
SUBSCRIPTION_ID=$(az account show -o tsv --query [id] | tr -d '\r')

echo "Adding $SP_ID to 'Contributor' role on $DEST_DATA_SHARE_ACCOUNT_NAME"
az role assignment create --role "Contributor" \
--assignee $SP_ID \
--scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.DataShare/accounts/$DEST_DATA_SHARE_ACCOUNT_NAME" \
--output none

echo "Adding $SP_ID to 'Contributor' role on $DEST_STORAGE_ACCOUNT_NAME"
az role assignment create --role "Contributor" \
--assignee $SP_ID \
--scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$DEST_STORAGE_ACCOUNT_NAME" \
--output none

echo "Adding $SP_ID to 'User Access Administrator' role on $DEST_STORAGE_ACCOUNT_NAME"
az role assignment create --role "User Access Administrator" \
--assignee $SP_ID \
--scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$DEST_STORAGE_ACCOUNT_NAME" \
--output none

echo "All Done!"