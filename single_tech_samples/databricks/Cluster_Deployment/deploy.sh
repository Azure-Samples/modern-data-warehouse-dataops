#!/usr/bin/env bash

AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
AZURE_RESOURCE_GROUP_NAME=${AZURE_RESOURCE_GROUP_NAME:-}
AZURE_RESOURCE_GROUP_LOCATION=${AZURE_RESOURCE_GROUP_LOCATION:-}

if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]
then
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified."
    exit 1
fi
if [[ -z "$AZURE_RESOURCE_GROUP_NAME" ]]
then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_NAME] specified."
    exit 1
fi
if [[ -z "$AZURE_RESOURCE_GROUP_LOCATION" ]]
then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_LOCATION] specified."
    exit 1
fi

# Login to Azure and select the subscription
if ! AZURE_USERNAME=$(az account show --query user.name);
then
    echo "No Azure account logged in, now trying to log in."
    az login
else
    echo "Logged in as $AZURE_USERNAME, set the active subscription to \"$AZURE_SUBSCRIPTION_ID\""
    az account set -s "$AZURE_SUBSCRIPTION_ID"
fi

# Check the resource group and region
RG_EXISTS=$(az group exists --resource-group "$AZURE_RESOURCE_GROUP_NAME")
if [[ $RG_EXISTS == "false" ]]
then
    echo "Creating resource group $AZURE_RESOURCE_GROUP_NAME in $AZURE_RESOURCE_GROUP_LOCATION."
    az group create --location "$AZURE_RESOURCE_GROUP_LOCATION" --resource-group "$AZURE_RESOURCE_GROUP_NAME"
else
    echo "Resource group $AZURE_RESOURCE_GROUP_NAME exists in $AZURE_RESOURCE_GROUP_LOCATION."
    RG_LOCATION=$(az group show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --query location)
    if [[ "$RG_LOCATION" != "\"$AZURE_RESOURCE_GROUP_LOCATION\"" ]]
    then
        echo "Resource group $AZURE_RESOURCE_GROUP_NAME is located in $RG_LOCATION, not \"$AZURE_RESOURCE_GROUP_LOCATION\""
    fi
fi