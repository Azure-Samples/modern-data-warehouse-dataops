#!/bin/bash

# check required variables are specified.

if [ -z "$AZDO_PROJECT" ]
then 
    echo "Please specify a target Azure DevOps project where Azure Pipelines and Variable groups will be deploy using AZDO_PROJECT environment variable"
    exit 1
fi

if [ -z "$AZDO_ORGANIZATION_URL" ]
then 
    echo "Please specify a Azure DevOps organization url using the AZDO_ORGANIZATION_URL environment variable in this form: https://dev.azure.com/<organization>/"
    exit 1
fi

if [ -z "$AZURE_DEVOPS_EXT_PAT" ]
then 
    echo "Please specify a Azure DevOps PAT token using the AZURE_DEVOPS_EXT_PAT environment variable."
    exit 1
fi

# initialise optional variables.

ENV_NAME=${ENV_NAME:-}
if [ -z "$ENV_NAME" ]
then 
    export ENV_NAME="dev"
    echo "No environment name [ENV_NAME] specified, defaulting to $ENV_NAME"
fi

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
    export AZURE_SUBSCRIPTION_ID=$(az account show --output json | jq -r '.id')
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified. Using default subscription id."
fi
