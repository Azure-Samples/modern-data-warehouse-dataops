#!/usr/bin/env bash

set -e

DEPLOYMENT_PREFIX=${DEPLOYMENT_PREFIX:-}
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
AZURE_RESOURCE_GROUP_NAME=${AZURE_RESOURCE_GROUP_NAME:-}
AZURE_RESOURCE_GROUP_LOCATION=${AZURE_RESOURCE_GROUP_LOCATION:-}
CLUSTER_CONFIG=${CLUSTER_CONFIG:-}
CLUSTER_CONFIG_HC=${CLUSTER_CONFIG_HC:-}

if [[ -z "$DEPLOYMENT_PREFIX" ]]; then
    echo "No deployment prefix [DEPLOYMENT_PREFIX] specified."
    exit 1
fi
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified."
    exit 1
fi
if [[ -z "$AZURE_RESOURCE_GROUP_NAME" ]]; then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_NAME] specified."
    exit 1
fi
if [[ -z "$AZURE_RESOURCE_GROUP_LOCATION" ]]; then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_LOCATION] specified."
    echo "Default location will be set to -> westus"
    AZURE_RESOURCE_GROUP_LOCATION="westus"
fi
if [[ -z "$CLUSTER_CONFIG" ]]; then
    echo "No Azure resource group [CLUSTER_CONFIG] specified, use default ./cluster-config.example.json"
    CLUSTER_CONFIG="./cluster-config.default.json"
fi
if [[ -z "$CLUSTER_CONFIG_HC" ]]; then
    echo "No Azure resource group [CLUSTER_CONFIG_HC] specified, use default ./cluster-config.example.json"
    CLUSTER_CONFIG_HC="./cluster-config.high-concurrency.json"
fi

# Get WorkspaceUrl from Azure Databricks

adbName="${DEPLOYMENT_PREFIX}adb01"
echo "Getting WorkspaceId & Url from Azure Databricks instance $adbName"

adbId=$(az databricks workspace show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$adbName" --query id --output tsv)
echo "Got adbId=${adbId}"
adbWorkspaceUrl=$(az databricks workspace show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$adbName" --query workspaceUrl --output tsv)
echo "Got adbWorkspaceUrl=${adbWorkspaceUrl}"

# Generate Azure Databricks PAT token

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
echo "Got adbGlobalToken=\"${adbGlobalToken:0:20}...${adbGlobalToken:(-20)}\""
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)
echo "Got azureApiToken=\"${azureApiToken:0:20}...${azureApiToken:(-20)}\""

# Generate all headers
authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$adbId"

# Deploy the cluster based on the configuration file
configs=("$CLUSTER_CONFIG" "$CLUSTER_CONFIG_HC")
for config in "${configs[@]}"; do
    echo "Deploying cluster with configuration $config"
    jq <"$config"
    clusterName=$(jq -r '.cluster_name' <"$config")

    echo "Creating cluster \"$clusterName\" in Azure Databricks"

    currentClusterCount=$(curl -sS -X GET -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        "https://${adbWorkspaceUrl}/api/2.0/clusters/list" |
        jq "[ .clusters | .[]? | select(.cluster_name == \"${clusterName}\") ] | length")
    if [[ "$currentClusterCount" -gt "0" ]]; then
        echo "Cluster \"$clusterName\" already exists in Azure Databricks, updating..."
        clusterIdToUpdate=$(curl -sS -X GET -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
            "https://${adbWorkspaceUrl}/api/2.0/clusters/list" |
            jq -r "[ .clusters | .[] | select(.cluster_name == \"${clusterName}\") ][0].cluster_id")

        echo "Updating cluster \"$clusterIdToUpdate\""
        jq -r ".cluster_id = \"$clusterIdToUpdate\"" <"$config"  |
            curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
                --data-binary "@-" "https://${adbWorkspaceUrl}/api/2.0/clusters/edit" |
            jq
        echo "Cluster \"$clusterName\" is being updated."
    else
        curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
            --data-binary "@${config}" "https://${adbWorkspaceUrl}/api/2.0/clusters/create" |
            jq
        echo "Cluster \"$clusterName\" is being created."
    fi
done
