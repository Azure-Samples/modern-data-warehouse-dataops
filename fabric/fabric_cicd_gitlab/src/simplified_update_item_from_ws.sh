#!/bin/bash

# -----------------------------------------------------------------------------
# Script to download the definition of a Fabric item (e.g., Dataset, Pipeline, etc.)
# and store it in a specified folder.
# The script checks if the API token is expired and refreshes it if needed.
# It also retrieves the workspace ID based on the provided workspace name.
# -----------------------------------------------------------------------------
set -e

. ./src/fabric_api_helpers.sh

source ./config/.env

# Validate input arguments: workspaceName, itemName, itemType, folder
if [ "$#" -ne 4 ]; then
    log "Usage: $0 <workspaceName> <itemName> <itemType> <folder>"
    exit 1
fi

workspaceName="$1"   # Fabric workspace name
itemName="$2"        # Fabric item name whose definition should be downloaded
itemType="$3"        # Fabric item type used to filter the results
folder="$4"          # Destination folder for the definition file

# Check required environment variables
if [ -z "$FABRIC_API_BASEURL" ] || [ -z "$FABRIC_USER_TOKEN" ]; then
    log "FABRIC_API_BASEURL or FABRIC_USER_TOKEN is not set in the env file."
    exit 1
fi

# create destination folder if needed
mkdir -p "$folder"

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
# Get the workspace ID from Fabric using a helper function 
# -----------------------------------------------------------------------------
workspace_id=$(get_workspace_id "$workspaceName")
if [ -z "$workspace_id" ]; then
    log "Error: Could not find workspace $workspaceName."
    exit 1
fi
log "Found workspace '$workspaceName' with ID: '$workspace_id'"

# -----------------------------------------------------------------------------
# Retrieve the item definition for the specified item if it exists
# Handle items that don't have a definition such as Lakehouse, Environment
# For these items, the API returns only the .platform file
# -----------------------------------------------------------------------------
get_and_store_item "$workspace_id" "$itemName" "$itemType" "$folder"

log "Script successfully completed." "success"
