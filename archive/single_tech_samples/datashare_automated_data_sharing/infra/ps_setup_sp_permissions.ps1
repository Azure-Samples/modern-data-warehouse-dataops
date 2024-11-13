if ($args.count -ne 2) {
    Write-Output "Usage: ./ps_setup_permissions.ps1 <suffix> <objectId>"
    exit
}

$SUFFIX = $args[0]
$SP_ID = $args[1]
$RG_NAME = "data-share-automation"
$DEST_STORAGE_ACCOUNT_NAME = "deststorage$SUFFIX"
$DEST_DATA_SHARE_ACCOUNT_NAME = "dest-data-share$SUFFIX"

Write-Output "Getting subscription Id..."
$SUBSCRIPTION_ID = $(az account show -o tsv --query [id])

Write-Output "Adding $SP_ID to 'Contributor' role on $DEST_DATA_SHARE_ACCOUNT_NAME"
az role assignment create --role "Contributor" `
    --assignee $SP_ID `
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.DataShare/accounts/$DEST_DATA_SHARE_ACCOUNT_NAME" `
    --output none

Write-Output "Adding $SP_ID to 'Contributor' role on $DEST_STORAGE_ACCOUNT_NAME"
az role assignment create --role "Contributor" `
    --assignee $SP_ID `
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$DEST_STORAGE_ACCOUNT_NAME" `
    --output none

Write-Output "Adding $SP_ID to 'User Access Administrator' role on $DEST_STORAGE_ACCOUNT_NAME"
az role assignment create --role "User Access Administrator" `
    --assignee $SP_ID `
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$DEST_STORAGE_ACCOUNT_NAME" `
    --output none

Write-Output "All Done!"