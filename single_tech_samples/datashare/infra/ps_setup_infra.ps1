if ($args.count -lt 1) {
    Write-Output "No parameter passed. Please provide a suffix to guarantee uniqueness of resource names"
    exit
}

$SUFFIX = $args[0]
$RG_NAME = "data-share-automation"
$LOCATION = "westeurope"
$SOURCE_STORAGE_ACCOUNT_NAME = "sourcestorage$SUFFIX"
$DEST_STORAGE_ACCOUNT_NAME = "deststorage$SUFFIX"
$SOURCE_DATA_SHARE_ACCOUNT_NAME = "source-data-share$SUFFIX"
$DEST_DATA_SHARE_ACCOUNT_NAME = "dest-data-share$SUFFIX"
$CONTAINER_NAME = "share-data"

Write-Output "Getting subscription Id..."
$SUBSCRIPTION_ID=$(az account show -o tsv --query id)
Write-Output "Creating resources on subscription $SUBSCRIPTION_ID"
Write-Output "Creating resource group '$RG_NAME'"
az group create -l $LOCATION -g $RG_NAME -o none
Write-Output "Creating source storage account '$SOURCE_STORAGE_ACCOUNT_NAME'"
az storage account create -l $LOCATION -g $RG_NAME -n $SOURCE_STORAGE_ACCOUNT_NAME --hns True --kind StorageV2 -o none
Write-Output "Creating destination storage account '$DEST_STORAGE_ACCOUNT_NAME'"
az storage account create -l $LOCATION -g $RG_NAME -n $DEST_STORAGE_ACCOUNT_NAME --hns True --kind StorageV2 -o none
Write-Output "Creating source data share account '$SOURCE_DATA_SHARE_ACCOUNT_NAME'"
az datashare account create -l $LOCATION -g $RG_NAME -n $SOURCE_DATA_SHARE_ACCOUNT_NAME -o none --only-show-errors
Write-Output "Creating destination data share account '$DEST_DATA_SHARE_ACCOUNT_NAME'"
az datashare account create -l $LOCATION -g $RG_NAME -n $DEST_DATA_SHARE_ACCOUNT_NAME -o none --only-show-errors

Write-Output "Adding MSI of $SOURCE_DATA_SHARE_ACCOUNT_NAME to 'Storage Blob Data Reader' on $SOURCE_STORAGE_ACCOUNT_NAME"
$SOURCE_MSI=$(az datashare account show -g $RG_NAME --name $SOURCE_DATA_SHARE_ACCOUNT_NAME -o tsv --query [identity.principalId] --only-show-errors)
az role assignment create --role "Storage Blob Data Reader" `
--assignee $SOURCE_MSI `
--scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$SOURCE_STORAGE_ACCOUNT_NAME" `
--output none

Write-Output "Adding MSI of $DEST_DATA_SHARE_ACCOUNT_NAME to 'Storage Blob Data Contributor' on $DEST_STORAGE_ACCOUNT_NAME"
$DEST_MSI=$(az datashare account show -g $RG_NAME --name $DEST_DATA_SHARE_ACCOUNT_NAME -o tsv --query [identity.principalId] --only-show-errors)
az role assignment create --role "Storage Blob Data Contributor" `
--assignee $DEST_MSI `
--scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$DEST_STORAGE_ACCOUNT_NAME" `
--output none

Write-Output "Retrieving storage key to upload sample data..."
$KEY=$(az storage account keys list -g $RG_NAME -n $SOURCE_STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

Write-Output "Creating container '$CONTAINER_NAME' in '$SOURCE_STORAGE_ACCOUNT_NAME'"
az storage container create --account-name $SOURCE_STORAGE_ACCOUNT_NAME --account-key $KEY -n $CONTAINER_NAME -o none
Write-Output "Uploading data..."
az storage blob upload --account-name $SOURCE_STORAGE_ACCOUNT_NAME --account-key $KEY --container $CONTAINER_NAME -f Readme.md --overwrite -o none --only-show-errors
Write-Output "All Done!"
