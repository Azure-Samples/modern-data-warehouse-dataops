#!/bin/bash

# -----------------------------------------------------------------------------
# Script to upload the definition of a Fabric item (e.g., Dataset, Pipeline, etc.)
# from local filesystem to the specified Microsoft Fabric workspace.
# The script checks if the API token is expired and refreshes it if needed.
# It also retrieves the workspace ID based on the provided workspace name.
# -----------------------------------------------------------------------------
set -e

. ./src/fabric_api_helpers.sh

# Load environment variables from the .env file
source ./config/.env

# Validate input arguments: workspaceName, itemName, itemType, folder
if [ "$#" -ne 2 ]; then
    log "Usage: $0 <workspaceName> <item-folder>"
    exit 1
fi

workspaceName="$1"   # Fabric workspace name
item_folder="$2"     # The source folder where the item definition files are located

# Check if the item folder exists
if [ ! -d "$item_folder" ]; then
    log "Error: Item folder '$item_folder' does not exist."
    exit 1
fi
# Check if the item folder contains a .platform file
if [ ! -f "$item_folder/.platform" ]; then
    log "Error: No .platform file found in the item folder '$item_folder'."
    exit 1
fi

# Check required environment variables
if [ -z "$FABRIC_API_BASEURL" ] || [ -z "$FABRIC_USER_TOKEN" ]; then
    log "FABRIC_API_BASEURL or FABRIC_USER_TOKEN is not set in the env file."
    exit 1
fi

# -----------------------------------------------------------------------------
# Check if the API token is expired and refresh if needed using refresh_api_token.sh
# -----------------------------------------------------------------------------
if [[ $(is_token_expired) = "1" ]]; then
    log "API token has expired. Refreshing token..."
    # Call refresh_api_token.sh.
    ./src/refresh_api_token.sh 
    # Reload environment variables after token refresh.
    source ./config/.env
    log "Token refreshed."
fi

# -----------------------------------------------------------------------------
# Get the workspace ID from Fabric
# -----------------------------------------------------------------------------
workspaceId=$(get_workspace_id "$workspaceName")
if [ -z "$workspaceId" ]; then
    log "Error: Could not find workspace $workspaceName."
    exit 1
fi
log "Found workspace '$workspaceName' with ID: '$workspaceId'"

# -----------------------------------------------------------------------------
# call the create_or_update_item function to create or update the item
# -----------------------------------------------------------------------------

create_or_update_item "$workspaceId" "$item_folder"

log "Script successfully completed." "success"
