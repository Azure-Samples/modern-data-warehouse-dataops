#!/usr/bin/env bash

set -e

AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}

if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified."
    exit 1
fi

if ! AZURE_USERNAME=$(az account show --query user.name --output tsv); then
    echo "No Azure account logged in, now trying to log in."
    az login --output none
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
else
    echo "Logged in as $AZURE_USERNAME, set the active subscription to \"$AZURE_SUBSCRIPTION_ID\""
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
fi

/bin/bash ./scripts/upload-sample-data.sh
/bin/bash ./scripts/deploy-default-and-hc-clusters.sh
/bin/bash ./scripts/configure-databricks-cli.sh
/bin/bash ./scripts/import-data-access-notebooks.sh