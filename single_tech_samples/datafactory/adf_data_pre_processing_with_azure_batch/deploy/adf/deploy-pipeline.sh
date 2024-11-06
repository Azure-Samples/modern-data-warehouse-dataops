#!/bin/sh

AZ_RESOURCE_GROUP="<YOUR-RESOURCEGROUP-NAME>"
AZ_BATCH_ACCOUNT_NAME="<YOUR-BATCH-ACCOUNT-NAME>"
AZ_BATCH_ACCOUNT_URL="<YOUR-BATCH-ACCOUNT-URL>"
AZ_BATCH_ORCHESTRATOR_POOL_ID="<YOUR-ORCHESTRATION-POOL-NAME>"
AZ_DATAFACTORY_NAME="<YOUR-DATAFACTORY-NAME>"


# Update the batch variables in azure batch linked service
sed -e "s/TEMP_AZ_BATCH_ACCOUNT_NAME/$AZ_BATCH_ACCOUNT_NAME/" -e "s|TEMP_AZ_BATCH_ACCOUNT_URL|$AZ_BATCH_ACCOUNT_URL|" -e "s/TEMP_AZ_BATCH_ORCHESTRATOR_POOL_ID/$AZ_BATCH_ORCHESTRATOR_POOL_ID/" linkedService/azurebatch_ls.json > linkedService/temp_azurebatch_ls.json

az datafactory linked-service create --resource-group $AZ_RESOURCE_GROUP --factory-name $AZ_DATAFACTORY_NAME --linked-service-name "AzureBlobStorage_LS" --properties "@linkedService/azurebatchstorage_ls.json"
az datafactory linked-service create --resource-group $AZ_RESOURCE_GROUP --factory-name $AZ_DATAFACTORY_NAME --linked-service-name "AzureBatch_LS" --properties "@linkedService/temp_azurebatch_ls.json"
az datafactory pipeline create --resource-group $AZ_RESOURCE_GROUP --factory-name $AZ_DATAFACTORY_NAME --pipeline-name "sample-pipeline" --pipeline "@pipeline/pipeline.json"
