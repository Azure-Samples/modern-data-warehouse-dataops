#!/bin/bash

# initialise optional variables.

DEPLOYMENT_ID=${DEPLOYMENT_ID:-}
if [ -z "$DEPLOYMENT_ID" ]
then 
    export DEPLOYMENT_ID="$(random_str 5)"
    echo "No deployment id [DEPLOYMENT_ID] specified, defaulting to $DEPLOYMENT_ID"
fi

RESOURCE_GROUP_NAME_PREFIX=${RESOURCE_GROUP_NAME_PREFIX:-}
if [ -z $RESOURCE_GROUP_NAME_PREFIX ]
then 
    export RESOURCE_GROUP_NAME_PREFIX="mdw-dataops-parking-${DEPLOYMENT_ID}"
    echo "No resource group name [RESOURCE_GROUP_NAME] specified, defaulting to $RESOURCE_GROUP_NAME_PREFIX"
fi

RESOURCE_GROUP_LOCATION=${RESOURCE_GROUP_LOCATION:-}
if [ -z $RESOURCE_GROUP_LOCATION ]
then    
    export RESOURCE_GROUP_LOCATION="westus"
    echo "No resource group location [RESOURCE_GROUP_LOCATION] specified, defaulting to $RESOURCE_GROUP_LOCATION"
fi

AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
if [ -z $AZURE_SUBSCRIPTION_ID ]
then
    export AZURE_SUBSCRIPTION_ID=$(az account show --output json | jq -r '.id')
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified. Using default subscription id."
fi

AZURESQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD:-}
if [ -z $AZURESQL_SERVER_PASSWORD ]
then 
    export AZURESQL_SERVER_PASSWORD="mdwdo-azsql-SqlP@ss-${DEPLOYMENT_ID}"
    echo "No password for sql server specified, defaulting to $AZURESQL_SERVER_PASSWORD"
fi