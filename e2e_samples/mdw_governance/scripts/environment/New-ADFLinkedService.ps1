#!/usr/bin/env pwsh

# Create an Linked Service to the Data Lake

$properties = '{
 \"type\": \"AzureBlobFS\",
 \"typeProperties\":
       {
 	\"url\": \"https://' + $env:STORAGE_ACCOUNT_NAME + '.dfs.core.windows.net\"
       }
    }'

# Create DataLakeStorage linked service
az datafactory linked-service create --factory-name $env:DATA_FACTORY_NAME --properties $properties --name DataLakeStorage -g $env:RESOURCE_GROUP

# Create SourceDataStorage linked service; in this example the same storage account 
az datafactory linked-service create --factory-name $env:DATA_FACTORY_NAME --properties $properties --name SourceDataStorage -g $env:RESOURCE_GROUP

$properties = '{
\"type\": \"AzureKeyVault\",
\"typeProperties\": 
      {
      \"baseUrl\": \"https://' + $env:KEYVAULT_NAME + '.vault.azure.net/\"
        }
      }'

# Create KeyVault linked service 

az datafactory linked-service create --factory-name $env:DATA_FACTORY_NAME --properties $properties --name KeyVault -g $env:RESOURCE_GROUP
