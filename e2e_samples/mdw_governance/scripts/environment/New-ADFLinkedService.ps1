#!/usr/bin/env pwsh

# Create an Linked Service to the Data Lake

$properties = '{
 \"type\": \"AzureBlobFS\",
 \"typeProperties\":
       {
 	\"url\": \"https://' + $env:STORAGE_ACCOUNT_NAME + '.dfs.core.windows.net\"
       }
    }'

az datafactory linked-service create --factory-name $env:DATA_FACTORY_NAME --properties $properties --name $env:STORAGE_ACCOUNT_NAME -g $env:RESOURCE_GROUP
