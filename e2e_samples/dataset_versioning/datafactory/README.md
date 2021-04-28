# Overview

This folder is for Data pipeline which copy data from SQL DB to Azure Storage (Delta Lake). We are using Azure Data Factory to implement pipeline.

## Prerequisites

- [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Provision Azure Resources by IaC (Terraform)](../infra/README.md)

## How to deploy

Ensure you are in `e2e_samples/dataset-versioning/datafactory/`.

Run command to deploy business logic into Azure Data Factory ([document](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli#deploy-local-template-or-bicep-file)). You can utilize Terraform script `arm_deploy_script` output which you get in provisioning step.

### Command

```bash
az deployment group create --name {Your deployment name} --resource-group {Your resource group name} --template-file ./arm_template/arm_template.json --parameters factoryName="{Your data factory name}" KeyVault_properties_typeProperties_baseUrl="{Your key vault url}" AzureBlobFS_properties_typeProperties_serviceEndpoint="{Your blob storage url}"
```

### Example

```bash
az deployment group create --name arm_deploy --resource-group rg-masatf2 --template-file ./arm_template/arm_template.json --parameters factoryName='adf-masatfapp-dev' KeyVault_properties_typeProperties_baseUrl='https://kv-masatfapp-dev-eastus.vault.azure.net/' AzureBlobFS_properties_typeProperties_serviceEndpoint='https://dlsmasatfappdev.blob.core.windows.net/'
```

### Parameters in deployment script

|Name|Description|
|--|--|
|`factoryName`|Azure Data Factory name where you'll deploy ARM template into|
|`KeyVault_properties_typeProperties_baseUrl`|Your key vault url|
|`AzureBlobFS_properties_typeProperties_serviceEndpoint`|Azure Blob Storage endpoint (url)|
