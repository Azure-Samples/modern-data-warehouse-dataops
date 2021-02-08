#!/bin/bash

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
    deployment_id="$(random_str 5)"
    export DEPLOYMENT_ID=$deployment_id
    echo "No deployment id [DEPLOYMENT_ID] specified, defaulting to $DEPLOYMENT_ID"
fi

RESOURCE_GROUP_NAME_PREFIX=${RESOURCE_GROUP_NAME_PREFIX:-}
if [ -z "$RESOURCE_GROUP_NAME_PREFIX" ]
then
    resource_group_name_prefix="mdwdo-park-${DEPLOYMENT_ID}"
    export RESOURCE_GROUP_NAME_PREFIX=$resource_group_name_prefix
    echo "No resource group name [RESOURCE_GROUP_NAME] specified, defaulting to $RESOURCE_GROUP_NAME_PREFIX"
fi

RESOURCE_GROUP_LOCATION=${RESOURCE_GROUP_LOCATION:-}
if [ -z "$RESOURCE_GROUP_LOCATION" ]
then
    resource_group_location="westus"
    export RESOURCE_GROUP_LOCATION=$resource_group_location
    echo "No resource group location [RESOURCE_GROUP_LOCATION] specified, defaulting to $RESOURCE_GROUP_LOCATION"
fi

AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
if [ -z "$AZURE_SUBSCRIPTION_ID" ]
then
    azure_subscription_id=$(az account show --output json | jq -r '.id')
    export AZURE_SUBSCRIPTION_ID=$azure_subscription_id
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified. Using default subscription id."
fi

AZDO_PIPELINES_BRANCH_NAME=${AZDO_PIPELINES_BRANCH_NAME:-}
if [ -z "$AZDO_PIPELINES_BRANCH_NAME" ]
then
    azdo_pipelines_branch_name="master"
    export AZDO_PIPELINES_BRANCH_NAME=$azdo_pipelines_branch_name
    echo "No branch name in [AZDO_PIPELINES_BRANCH_NAME] specified. defaulting to $AZDO_PIPELINES_BRANCH_NAME."
fi

AZURESQL_SERVER_PASSWORD=${AZURESQL_SERVER_PASSWORD:-}
if [ -z "$AZURESQL_SERVER_PASSWORD" ]
then
    azuresql_server_password="mdwdo-azsql-SqlP@ss-${DEPLOYMENT_ID}"
    export AZURESQL_SERVER_PASSWORD=$azuresql_server_password
    echo "No password for sql server specified, defaulting to $AZURESQL_SERVER_PASSWORD"
fi