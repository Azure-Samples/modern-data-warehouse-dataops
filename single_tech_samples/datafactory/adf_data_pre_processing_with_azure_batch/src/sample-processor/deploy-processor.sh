#!/bin/sh

RESOURCE_GROUP_NAME="<YOUR-RESOURCE-GROUP-NAME>"
STORAGE_ACCOUNT_NAME="<YOUR-ADLS-STORAGE-ACCOUNT>"
CONTAINER_REGISTRY_NAME="<YOUR-ACR-NANME>"

docker build . -t sample-processor:latest

az acr login --name $CONTAINER_REGISTRY_NAME

docker tag sample-processor:latest  $CONTAINER_REGISTRY_NAME.azurecr.io/sample-processor:latest
docker push $CONTAINER_REGISTRY_NAME.azurecr.io/sample-processor:latest


#Add your client ip to access storage account.
IP_ADDRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
az storage account network-rule add -g $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --ip-address $IP_ADDRESS

#Upload sample file
az storage blob upload -f "data/raw/sample-data.bag" -c data/raw --account-name "$STORAGE_ACCOUNT_NAME"

#Create extracted path.
az storage blob directory create -c data -d extracted --account-name "$STORAGE_ACCOUNT_NAME"