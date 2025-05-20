#!/bin/bash

. ./scripts/common.sh
# Source enviroment variables
source .devcontainer/.env

#Check variables are set for login.
if [ -z "${TENANT_ID:-}" ]
then
    log "To run this script the TENANT_ID is required. Ensure your .devcontainer/.env file contains the required variables." "error"
    exit 1
fi
if [ -z "${AZURE_SUBSCRIPTION_ID:-}" ]
then
    log "To run this script the AZURE_SUBSCRIPTION_ID is required. Ensure your .devcontainer/.env file contains the required variables." "error"
    exit 1
fi
if [ -z "${AZDO_ORGANIZATION_URL:-}" ]
then
    log "To run this script the AZDO_ORGANIZATION_URL is required. Ensure your .devcontainer/.env file contains the required variables." "error"
    exit 1
fi
if [ -z "${AZDO_PROJECT:-}" ]
then
    log "To run this script the AZDO_PROJECT is required. Ensure your .devcontainer/.env file contains the required variables." "error"
    exit 1
fi
if [ -z "$GITHUB_REPO" ]
then 
    log "Please specify a github repo using the GITHUB_REPO environment variable in this form '<my_github_handle>/<repo>'. (ei. 'devlace/mdw-dataops-import')" "danger"
    exit 1
fi
if [ -z "$GITHUB_PAT_TOKEN" ]
then 
    log "Please specify a github PAT token using the GITHUB_PAT_TOKEN environment variable." "danger"
    exit 1
fi

# initialise optional variables.
DEPLOYMENT_ID=${DEPLOYMENT_ID:-}
if [ -z "$DEPLOYMENT_ID" ]
then 
    export DEPLOYMENT_ID="$(random_str 5)"
    log "No deployment id [DEPLOYMENT_ID] specified, defaulting to $DEPLOYMENT_ID" "info"
fi

AZURE_LOCATION=${AZURE_LOCATION:-}
if [ -z "$AZURE_LOCATION" ]
then    
    export AZURE_LOCATION="westus"
    log "No resource group location [AZURE_LOCATION] specified, defaulting to $AZURE_LOCATION" "info"
fi

AZDO_PIPELINES_BRANCH_NAME=${AZDO_PIPELINES_BRANCH_NAME:-}
if [ -z "$AZDO_PIPELINES_BRANCH_NAME" ]
then
    export AZDO_PIPELINES_BRANCH_NAME="main"
    log "No branch name in [AZDO_PIPELINES_BRANCH_NAME] specified. defaulting to $AZDO_PIPELINES_BRANCH_NAME." "info"
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
    log "No ENABLE_KEYVAULT_SOFT_DELETE specified. Defaulting to $ENABLE_KEYVAULT_SOFT_DELETE" "info"
fi

ENABLE_KEYVAULT_PURGE_PROTECTION=${ENABLE_KEYVAULT_PURGE_PROTECTION:-}
if [ -z "$ENABLE_KEYVAULT_PURGE_PROTECTION" ]
then 
    # set purge protection variable to true if the env variable has not been set
    export ENABLE_KEYVAULT_PURGE_PROTECTION=${ENABLE_KEYVAULT_PURGE_PROTECTION:-true}
    log "No ENABLE_KEYVAULT_PURGE specified. Defaulting to $ENABLE_KEYVAULT_PURGE_PROTECTION" "info"
fi

ENV_DEPLOY=${ENV_DEPLOY:-}
if [ -z "$ENV_DEPLOY" ]
then
    export ENV_DEPLOY
    log "No Deployment option was specified in the configuration" "info"
fi

# Check if already logged in, it will logout first
if az account show > /dev/null 2>&1
then
    log "Already logged in. Logging out and logging in again." "info"
    az logout
fi

#Prompt login.
#if more than one subcription, choose the one that will be used to deploy the resources.
az config set core.login_experience_v2=off
az login --tenant $TENANT_ID
az config set core.login_experience_v2=on
az account set --subscription $AZURE_SUBSCRIPTION_ID --output none

az devops configure --defaults organization=$AZDO_ORGANIZATION_URL project=$AZDO_PROJECT --output none
