# Azure Data Factory Pipelines

This contains the ARM template definitions to deploy Azure Data Factory pipeline which copy data from SQL DB to Azure Storage (Delta Lake).

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Provisioned Azure Resources by IaC (Terraform)](../infra/README.md)

## Setup and Deployment

1. Ensure you are in `e2e_samples/dataset-versioning/datafactory/`.
1. Run the `arm_deploy_script` output from Terraform after you [provisioned Azure Resources by IaC (Terraform)](../infra/README.md). It will look like below:

```bash
az deployment group create --name {Your deployment name} --resource-group {Your resource group name} --template-file ./arm_template/arm_template.json --parameters factoryName="{Your data factory name}" KeyVault_properties_typeProperties_baseUrl="{Your key vault url}" AzureBlobFS_properties_typeProperties_serviceEndpoint="{Your blob storage url}"
```

Example of a populated command:

```bash
az deployment group create --name arm_deploy --resource-group rg-masatf2 --template-file ./arm_template/arm_template.json --parameters factoryName='adf-masatfapp-dev' KeyVault_properties_typeProperties_baseUrl='https://kv-masatfapp-dev-eastus.vault.azure.net/' AzureBlobFS_properties_typeProperties_serviceEndpoint='https://dlsmasatfappdev.blob.core.windows.net/'
```

### Parameters in deployment script

|Name|Description|
|--|--|
|`factoryName`|Azure Data Factory name where you'll deploy ARM template into|
|`KeyVault_properties_typeProperties_baseUrl`|Your key vault url|
|`AzureBlobFS_properties_typeProperties_serviceEndpoint`|Azure Blob Storage endpoint (url)|

See [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli#deploy-local-template-or-bicep-file) for more information about deploying ARM templates.

## Next step

Running the sample: [Load data into data source (Azure SQL Database)](../sql/data_generator/README.md)
