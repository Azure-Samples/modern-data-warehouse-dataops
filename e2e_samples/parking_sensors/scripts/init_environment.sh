#!/bin/bash


# Azlogin using enviroment variables

source .devcontainer/.env

#Prompt login.
#if more than one subcription, choose the one that will be used to deploy the resources.
# Check if already logged in, it will logout first

if az account show > /dev/null 2>&1; then
    echo "Already logged in. Logging out and logging in again."
    az logout
fi

az config set core.login_experience_v2=off
az login --tenant $TENANT_ID
az config set core.login_experience_v2=on
az account set -s $AZURE_SUBSCRIPTION_ID

az devops configure --defaults organization=$AZDO_ORGANIZATION_URL project=$AZDO_PROJECT

# check required variables are specified.

if [ -z "$GITHUB_REPO" ]
then 
    echo "Please specify a github repo using the GITHUB_REPO environment variable in this form '<my_github_handle>/<repo>'. (ei. 'devlace/mdw-dataops-import')"
    exit 1
fi

if [ -z "$GITHUB_PAT_TOKEN" ]
then 
    echo "Please specify a github PAT token using the GITHUB_PAT_TOKEN environment variable."
    exit 1
fi

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
    export AZURE_SUBSCRIPTION_ID=$(az account show --output json | jq -r '.id')
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified. Using default subscription id."
fi

AZDO_PIPELINES_BRANCH_NAME=${AZDO_PIPELINES_BRANCH_NAME:-}
if [ -z "$AZDO_PIPELINES_BRANCH_NAME" ]
then
    export AZDO_PIPELINES_BRANCH_NAME="main"
    echo "No branch name in [AZDO_PIPELINES_BRANCH_NAME] specified. defaulting to $AZDO_PIPELINES_BRANCH_NAME."
fi

AZURESQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD:-}
if [ -z "$AZURESQL_SERVER_PASSWORD" ]
then 
    #Increase the complexity by appending the complex string, as some passwords are not cmplex enough.
    export AZURESQL_SERVER_PASSWORD="P@_Sens0r$(makepasswd --chars 16)"
fi

ENABLE_KEYVAULT_SOFT_DELETE=${ENABLE_KEYVAULT_SOFT_DELETE:-}
if [ -z "$ENABLE_KEYVAULT_SOFT_DELETE" ]
then 
    # set soft delete variable to true if the env variable has not been set
    export ENABLE_KEYVAULT_SOFT_DELETE=${ENABLE_KEYVAULT_SOFT_DELETE:-true}
    echo "No ENABLE_KEYVAULT_SOFT_DELETE specified. Defaulting to $ENABLE_KEYVAULT_SOFT_DELETE"
fi

ENABLE_KEYVAULT_PURGE_PROTECTION=${ENABLE_KEYVAULT_PURGE_PROTECTION:-}
if [ -z "$ENABLE_KEYVAULT_PURGE_PROTECTION" ]
then 
    # set purge protection variable to true if the env variable has not been set
    export ENABLE_KEYVAULT_PURGE_PROTECTION=${ENABLE_KEYVAULT_PURGE_PROTECTION:-true}
    echo "No ENABLE_KEYVAULT_PURGE specified. Defaulting to $ENABLE_KEYVAULT_PURGE_PROTECTION"
fi