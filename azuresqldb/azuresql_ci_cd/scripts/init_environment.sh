#!/bin/bash

# check required variables are specified.

if [ -z $GITHUB_REPO_URL ]
then 
    echo "Please specify a github repo using the GITHUB_REPO_URL environment variable."
    exit 1
fi

if [ -z $GITHUB_PAT_TOKEN ]
then 
    echo "Please specify a github PAT token using the GITHUB_PAT_TOKEN environment variable."
    exit 1
fi

# initialise optional variables.

if [ -z $DEPLOYMENT_ID ]
then 
    export DEPLOYMENT_ID="$(random_str 5)"
    echo "No deployment id specified, defaulting to $DEPLOYMENT_ID"
fi

if [ -z $BRANCH_NAME ]
then 
    export BRANCH_NAME='main'
    echo "No working branch name specified, defaulting to $BRANCH_NAME"
fi

if [ -z $AZURESQL_SERVER_PASSWORD ]
then 
    export AZURESQL_SERVER_PASSWORD="mdwdo-azsql-SqlP@ss-${DEPLOYMENT_ID}"
    echo "No password for sql server specified, defaulting to $AZURESQL_SERVER_PASSWORD"
fi

if [ -z $RESOURCE_GROUP_NAME ]
then 
    export RESOURCE_GROUP_NAME="mdwdo-azsql-${DEPLOYMENT_ID}-rg"
    echo "No resource group name specified, defaulting to $RESOURCE_GROUP_NAME"
fi

if [ -z $RESOURCE_GROUP_LOCATION ]
then    
    export RESOURCE_GROUP_LOCATION="westus"
    echo "No resource group location specified, defaulting to $RESOURCE_GROUP_LOCATION"
fi
