#!/usr/bin/env pwsh

# Connect a Data Factory to Purview for lineage tracking
# Currently, to create a connection, you have to add a tag to the Data Factory

$dataFactory=(az datafactory show --name $env:DATA_FACTORY_NAME --resource-group $env:RESOURCE_GROUP |  ConvertFrom-Json)

$catalogAPI = "$env:PURVIEW_ACCOUNT_NAME.catalog.purview.azure.com"

$dataFactoryManagedIdentity = $dataFactory.identity.principalId
$dataFactoryResourceId = $dataFactory.id

az role assignment create --assignee-object-id $dataFactoryManagedIdentity --role "Purview Data Curator" --scope "/subscriptions/$env:SUBSCRIPTIONID/resourceGroups/$env:RESOURCE_GROUP/providers/Microsoft.Purview/accounts/$env:PURVIEW_ACCOUNT_NAME"

az tag create --resource-id $dataFactoryResourceId --tags catalogUri=$catalogAPI
