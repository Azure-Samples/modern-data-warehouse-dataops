#!/usr/bin/env pwsh

$managedIdentity = (az resource show -g $env:RESOURCE_GROUP -n $env:FUNCTION_APP_NAME --resource-type "Microsoft.Web/sites" | ConvertFrom-Json).identity.principalId
$scope = (az resource show -g $env:RESOURCE_GROUP -n $env:STORAGE_ACCOUNT_NAME --resource-type "Microsoft.Storage/storageAccounts" | ConvertFrom-Json).id

Write-Information "Got Managed Identity: $managedIdentity"
Write-Information "Got Scope: $scope"

az role assignment create --assignee-object-id $managedIdentity --role "Storage Blob Data Contributor" --scope $scope
