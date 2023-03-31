#!/bin/bash

# check required variables are specified.

# initialise optional variables.

DEPLOYMENT_ID=${DEPLOYMENT_ID:-}
if [ -z "$DEPLOYMENT_ID" ]
then 
    export DEPLOYMENT_ID="$(random_str 5)"
    echo "No deployment id [DEPLOYMENT_ID] specified, defaulting to $DEPLOYMENT_ID"
fi

AZURE_LOCATION=${AZURE_LOCATION:-}
if [ -z "$AZURE_LOCATION" ]
then    
    export AZURE_LOCATION="westus"
    echo "No resource group location [AZURE_LOCATION] specified, defaulting to $AZURE_LOCATION"
fi

AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
if [ -z "$AZURE_SUBSCRIPTION_ID" ]
then
    export AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified. Using default subscription id."
fi

SYNAPSE_SQL_PASSWORD=${SYNAPSE_SQL_PASSWORD:-}
if [ -z "$SYNAPSE_SQL_PASSWORD" ]
then 
    export SYNAPSE_SQL_PASSWORD="$(makepasswd --chars 16)"
    echo "No Synapse SQL password specified. Generating a new password. View this value in the .env.dev file or in Key Vault."
fi
