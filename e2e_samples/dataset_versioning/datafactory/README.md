# Overview
This folder is for Data pipeline which copy data from SQL DB to Azure Storage (Delta Lake). We are using Azure Data Factory to implement pipeline.

## How to deploy it
1. Provision Azure Resources by IaC (Terraform)
1. [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
1. Run command to deploy ([document](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli#deploy-local-template-or-bicep-file))
```
az deployment group create --name {Your deployment name. Anyname is OK} --resource-group {Your resource group name} --template-file ./arm_template.json --parameters factoryName="{Your data factory name}" KeyVault_properties_typeProperties_baseUrl="{Your key vault url}" AzureBlobFS_properties_typeProperties_serviceEndpoint="{Your blob storage url}"
```

### Parameters in deployment script
|Name|Description|
|--|--|
|factoryName|Azure Data Factory name where you'll deploy ARM template into|
|KeyVault_properties_typeProperties_baseUrl|Your key vault url|
|AzureSqlDatabase_properties_typeProperties_connectionString_secretName|Key Vault secret name which stores SQL Database connection string|
|AzureBlobFS_properties_typeProperties_serviceEndpoint|Azure Blob Storage endpoint (url)|
