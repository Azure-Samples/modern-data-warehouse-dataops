#!/usr/bin/env pwsh

if (Test-Path env:DataLakeDiagnosticLogRetentionDays) {
  $logRetention = [int]$env:DataLakeDiagnosticLogRetentionDays
}
else {
  $logRetention = 7
}
$scope = (az resource show -g $env:RESOURCE_GROUP -n $env:STORAGE_ACCOUNT_NAME --resource-type "Microsoft.Storage/storageAccounts" | ConvertFrom-Json).id

Write-Information "Got Log Retention: $logRetention"
Write-Information "Got Scope: $scope"

$key = (az storage account keys list -n $env:STORAGE_ACCOUNT_NAME | ConvertFrom-Json )[0].value
az storage logging update --account-name $env:STORAGE_ACCOUNT_NAME --services b --log rwd --version 2.0 --retention $logRetention --account-key $key