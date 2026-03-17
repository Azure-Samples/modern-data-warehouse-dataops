#!/bin/bash
set -o errexit

# Set authenticate flag to false by default if not provided
authenticate=${1:-false}
use_spn=${2:-false}

source ./config/.env

if [ "$authenticate" != "false" ] && [ "$use_spn" == "false" ]; then
    echo "Authenticating..."
    az config set core.login_experience_v2=off
    az login --tenant $TENANT_ID --use-device-code
    az config set core.login_experience_v2=on
else 
    if [ "$authenticate" != "false" ] && [ "$use_spn" != "false" ]; then
        # else if authenticate is not false and use_spn is not false authenticate with a service principal
        echo "Authenticating with service principal..."
        az login --service-principal -u $APP_CLIENT_ID -p $APP_CLIENT_SECRET --tenant $TENANT_ID --allow-no-subscription
    fi
fi

# grab an Entra token for the Fabric API
token=$(az account get-access-token \
    --resource "https://analysis.windows.net/powerbi/api" \
    --query "accessToken" \
    -o tsv | tr -d '\r')

# Refresh the token in the .env file
sed -i "s/FABRIC_USER_TOKEN=.*/FABRIC_USER_TOKEN=$token/" ./config/.env