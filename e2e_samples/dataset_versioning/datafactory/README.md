# Overview
This folder is for Data pipeline which copy data from SQL DB to Azure Storage (Delta Lake). We are using Azure Data Factory to implement pipeline.

## How to deploy it


### Parameters in deployment script
|Name|Description|
|--|--|
|factoryName|Azure Data Factory name where you'll deploy ARM template into|
|KeyVault_properties_typeProperties_baseUrl|Your key vault url|
|AzureSqlDatabase_properties_typeProperties_connectionString_secretName|Key Vault secret name which stores SQL Database connection string|
|AzureBlobFS_properties_typeProperties_serviceEndpoint|Azure Blob Storage endpoint (url)|