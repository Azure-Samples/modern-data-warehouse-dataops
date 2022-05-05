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

# Create Databricks linked service
$properties = '{
\"type\": \"AzureDatabricks\",
\"typeProperties\": 
      {
      \"domain\": \"https://' + $env:DATABRICKS_WORKSPACE_URL + '\",
      \"existingClusterId\": \"' + $env:DATABRICKS_CLUSTER_ID + '\",
      \"accessToken\": {
                \"type\": \"AzureKeyVaultSecret\",
                \"store\": {
                    \"referenceName\": \"KeyVault\",
                    \"type\": \"LinkedServiceReference\"
                },
                \"secretName\": \"' + $env:DATABRICKS_TOKEN_SECRET_NAME + '\"
            },
        }
      }'
az datafactory linked-service create --factory-name $env:DATA_FACTORY_NAME --properties $properties --name PresidioDatabricks -g $env:RESOURCE_GROUP
