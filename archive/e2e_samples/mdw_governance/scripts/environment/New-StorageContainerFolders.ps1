#!/usr/bin/env pwsh

# Creates a directory/folder with the given name into the given storage container and sets the permissions

Param(
    [Parameter(HelpMessage="Azure resource group")]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceGroup=$Env:RESOURCE_GROUP,

    [Parameter(HelpMessage="Storage account name")]
    [ValidateNotNullOrEmpty()]
    [String]
    $StorageAccountName=$Env:STORAGE_ACCOUNT_NAME,

    [Parameter(HelpMessage="Storage container name")]
    [ValidateNotNullOrEmpty()]
    [String]
    $StorageContainerName=$Env:STORAGE_CONTAINER_NAME,

    [Parameter(HelpMessage="Dropzone container name")]
    [ValidateNotNullOrEmpty()]
    [String]
    $DropzoneStorageContainerName=$Env:DROPZONE_STORAGE_CONTAINER_NAME

)

if (!($ResourceGroup `
    -and $StorageAccountName `
    -and $StorageContainerName )) {
    Throw "Argument(s) missing"
}

# Create folder structure
$folders = "Bronze", "Silver", "Gold", "Malformed", "Sys", "Sandbox"

foreach ($folderName in $folders) {
    $DirectoryExists = (az storage blob directory exists `
    --account-name $StorageAccountName `
    --container-name $StorageContainerName `
    --directory-path $folderName `
    | ConvertFrom-Json).exists

    if ($False -eq $DirectoryExists) {
        az storage blob directory create --account-name $StorageAccountName --container-name $StorageContainerName --directory-path $folderName
    }

}

# Copy files from data folder
az storage blob upload-batch --account-name $StorageAccountName --destination $DropzoneStorageContainerName --source ./data/raw_data/On-street_Parking_Bay_Sensors --pattern *.csv  
