#!/usr/bin/env pwsh

Param(
    [Parameter(HelpMessage="Azure resource group")]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceGroup=$Env:RESOURCE_GROUP,

    [Parameter(HelpMessage="Storage account name")]
    [ValidateNotNullOrEmpty()]
    [String]
    $StorageAccountName=$Env:STORAGE_ACCOUNT_NAME,

    [Parameter(HelpMessage="Resource Name")]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceName=$Env:RESOURCE_NAME,

    [Parameter(HelpMessage="Resource Type")]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceType=$Env:RESOURCE_TYPE

)


$managedIdentity = (az resource show -g $ResourceGroup -n $ResourceName --resource-type $ResourceType | ConvertFrom-Json).identity.principalId
$scope = (az resource show -g $ResourceGroup -n $StorageAccountName --resource-type "Microsoft.Storage/storageAccounts" | ConvertFrom-Json).id

Write-Information "Got Managed Identity: $managedIdentity"
Write-Information "Got Scope: $scope"

az role assignment create --assignee-object-id $managedIdentity --role "Storage Blob Data Contributor" --scope $scope
