#!/bin/bash

echo "Enter resource group to delete azure resources:"
read AZURE_RESOURCE_GROUP_NAME

if [[ -z "$AZURE_RESOURCE_GROUP_NAME" ]]; then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_NAME] specified."
    exit 1
fi


# Login to Azure and show the subscription
if [ ! -z "$AZURE_SUBSCRIPTION_ID" ]; then
    echo "Logged in as $AZURE_USERNAME, set the active subscription to \"$AZURE_SUBSCRIPTION_ID\""
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
else
    subscriptionId="$(az account show --query "id" --output tsv)"
    echo "Using $subscriptionId as your default subscription id."
fi

# Check the resource group and region
RG_EXISTS=$(az group exists --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output tsv)
if [[ $RG_EXISTS == "false" ]]; then
    echo "Error: Resource group $AZURE_RESOURCE_GROUP_NAME in $AZURE_RESOURCE_GROUP_LOCATION does not exist."
    exit 1
else
    echo "Resource group $AZURE_RESOURCE_GROUP_NAME exists. Removing created resources"
fi

echo "Deleting resource group: $AZURE_RESOURCE_GROUP_NAME with all the resources. In 5 seconds..."
sleep 5s
az group delete --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none --yes
