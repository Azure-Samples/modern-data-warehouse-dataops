#!/bin/bash

set -e

. ./refresh_api_token.sh
. ./fabric_api_helpers.sh

source ./config/.env


# Parameters
baseUrl=$FABRIC_API_BASEURL
fabricToken=$FABRIC_USER_TOKEN
capacityId=$FABRIC_CAPACITY_ID
folder=$ITEMS_FOLDER
resetConfig=${6:-false}
workspaceName=$1

# Functions
get_error_response() {
    echo "$1"
}

update_workspace_item_definition() {
    local baseUrl=$1
    local workspace_id=$2
    local requestHeader=$3
    local contentType=$4
    local itemMetadata=$5
    local itemDefinition=$6
    local itemConfig=$7

    uri="$baseUrl/workspaces/$workspace_id/items/$(echo "$itemConfig" | jq -r '.objectId')/updateDefinition"
    if [ "$(echo "$itemMetadata" | jq -r '.type')" == "Notebook" ] && [ -z "$(echo "$itemDefinition" | jq -r '.definition.format')" ]; then
        itemDefinition=$(echo "$itemDefinition" | jq '.definition.format = "ipynb"')
    fi
    body=$(jq -n --argjson definition "$(echo "$itemDefinition" | jq '.definition')" '{definition: $definition}')

    echo "Executing POST to update definition of item $(echo "$itemConfig" | jq -r '.objectId') $(echo "$itemMetadata" | jq -r '.displayName')"
    curl -s -X POST -H "$requestHeader" -H "Content-Type: $contentType" -d "$body" "$uri"
}

update_workspace_item() {
    local baseUrl=$1
    local workspace_id=$2
    local requestHeader=$3
    local contentType=$4
    local itemMetadata=$5
    local itemDefinition=$6
    local itemConfig=$7

    uri="$baseUrl/workspaces/$workspace_id/items/$(echo "$itemConfig" | jq -r '.objectId')"
    body=$(jq -n --arg displayName "$(echo "$itemMetadata" | jq -r '.displayName')" --arg description "$(echo "$itemMetadata" | jq -r '.description')" '{displayName: $displayName, description: $description}')

    echo "Executing PATCH to update item $(echo "$itemConfig" | jq -r '.objectId') $(echo "$itemMetadata" | jq -r '.displayName')"
    curl -s -X PATCH -H "$requestHeader" -H "Content-Type: $contentType" -d "$body" "$uri"

    if [ -n "$itemDefinition" ]; then
        update_workspace_item_definition "$baseUrl" "$workspace_id" "$requestHeader" "$contentType" "$itemMetadata" "$itemDefinition" "$itemConfig"
    fi
}

long_running_operation_polling() {
    local uri=$1
    local retryAfter=$2

    echo "Polling long running operation ID $uri has been started with a retry-after time of $retryAfter seconds."

    while true; do
        operationState=$(curl -s -H "$requestHeader" -H "Content-Type: $contentType" "$uri")
        status=$(echo "$operationState" | jq -r '.Status')

        echo "Long running operation status: $status"

        if [[ "$status" == "NotStarted" || "$status" == "Running" ]]; then
            sleep 20
        else
            break
        fi
    done

    if [ "$status" == "Failed" ]; then
        echo "The long running operation has been completed with failure. Error response: $(echo "$operationState" | jq '.')"
    else
        echo "The long running operation has been successfully completed."
        if [ -n "$responseHeadersLocation" ]; then
            uri="$responseHeadersLocation"
        else
            return
        fi
        item=$(curl -s -H "$requestHeader" -H "Content-Type: $contentType" "$uri")
        echo "$item"
    fi
}

# Main script
echo "The folder we are working on is $folder"
echo "Updating workspace items for workspace $workspaceName"

itemConfigFileName="item-config.json"
itemMetadataFileName="item-metadata.json"
itemDefinitionFileName="item-definition.json"

workspace_id=$(get_or_create_workspace "$workspaceName" "$capacityId")
workspaceItems=$(get_workspace_items "$workspace_id")
repoItems=()

dirs=$(find $folder -maxdepth 1 -mindepth 1 -type d)
for d in $dirs; do
    echo "$d"
    repoItems=($(create_or_update_workspace_item "$requestHeader" "$contentType" "$baseUrl" "$workspace_id" "$workspaceItems" "$d" "${repoItems[@]}"))
done

for item in $(echo "$workspaceItems" | jq -r '.[] | @base64'); do
    item=$(echo "$item" | base64 --decode)
    itemId=$(echo "$item" | jq -r '.id')
    itemType=$(echo "$item" | jq -r '.type')
    if [[ ! " ${repoItems[@]} " =~ " ${itemId} " ]] && [[ "$itemType" != "SQLEndpoint" && "$itemType" != "SemanticModel" ]]; then
        echo "Item $itemId $(echo "$item" | jq -r '.displayName') is in the workspace but not in the repository, deleting."
        curl -s -X DELETE -H "$requestHeader" -H "Content-Type: $contentType" "$baseUrl/workspaces/$workspace_id/items/$itemId"
    fi
done

echo "Script execution completed successfully. Workspace items have been updated for workspace $workspaceName."
