#!/bin/bash

. ./src/utilities.sh

#############################
##    Fabric functions
#############################

#----------------------------
# Workspaces
#----------------------------

# Function to get all workspaces names
get_workspace_names(){
    rest_call get "workspaces" "value[].displayName" tsv
    #az rest --method get --uri "$FABRIC_API_BASEURL/workspaces" --headers "Authorization=Bearer $FABRIC_USER_TOKEN" --query "value[].id" -o tsv
}

# Get workspace displayName by specifying a workspace id
get_workspace_name(){
    local workspace_id=$1
    rest_call get "workspaces/$workspace_id" "displayName" tsv
    #az rest --method get --uri "$FABRIC_API_BASEURL/workspaces/$workspace_id" --headers "Authorization=Bearer $token"
}

# Get workspace id by specifying a workspace displayName
get_workspace_id(){
    local workspace_name=$1
    rest_call get "workspaces" "value[?displayName=='$workspace_name'].id" tsv | tr -d '\r'
    #az rest --method get --uri "$FABRIC_API_BASEURL/workspaces/$workspace_id" --headers "Authorization=Bearer $token"
}

# Create a new workspace with the specified name using capacity id
create_workspace(){
    local workspace_name=$1
    local capacity_id=$2
    body=$(echo '{"displayName" : "'$workspace_name'", "capacityId" : "'$capacity_id'"}')

    rest_call "POST" "workspaces" "id" "tsv" "$body"
}

get_or_create_workspace() {
    # given a workspace name returns its id
    # if the workspace does not exist, creates it and returns its id
    # requires a capacity id and a workspace name

    local workspace_name=$1
    local capacity_id=$2

    workspace_id=$(get_workspace_id "$workspace_name")

    if [ -z "$workspace_id" ]; then
        log "A workspace with the requested name $workspace_name was not found, creating new workspace." 
        workspace_id=$(create_workspace "$workspace_name" "$capacity_id")
        log "Workspace $workspace_name with id $workspace_id was created." "success"
    else
        log "Workspace $workspace_name with id $workspace_id was found." "success"
    fi
    echo $workspace_id
}

#----------------------------
# Items
#----------------------------


get_workspace_items(){
    local workspace_id=$1
    # get all workspace items
    rest_call get "workspaces/$workspace_id/items" "value" "json"
}

get_item_id(){
    local workspace_id=$1
    local item_name="$2"
    local item_type=$3
    # rest_call get "workspaces/$workspace_id/items?type=$item_type" "value[?displayName=='$item_name'].id" tsv | tr -d '\r'
    echo $(get_item_by_name "$workspace_id" "$item_name" "$item_type" | jq -r '.id')
}

get_item_by_name(){
    local workspace_id=$1
    local item_name="$2"
    local item_type=$3
    rest_call get "workspaces/$workspace_id/items?type=$item_type" "value[?displayName=='$item_name'] | [0].{description: description, displayName: displayName, type: type, id: id}" "json" | tr -d '\r'
}

get_and_store_item(){
    local workspace_id="$1"
    local item_name="$2"
    local item_type="$3"
    local folder="$4"
    # This function retrieves the definition of an item
    # requires as inputs the workspace id, the item name and the item type
    # If the item type supports retrieving the definition then it will return that
    # else it will return the item metadata
    log "Retrieving item '$item_name' of type '$item_type' from workspace '$workspace_id'"
    if [ $item_type == "Notebook" ] || [ $item_type == "DataPipeline" ]; then
        # When the item supports definition then use the getDefinition API
        item_definition=$(get_item_definition "$workspace_id" "$item_name" "$item_type")
        if [ -z "$item_definition" ]; then
            log "Failed to retrieve definition for item $item_name of type $item_type."
            return 1
        fi
        log "Saving definition to file..."
        store_item_definition "$folder" "$item_name" "$item_type" "$item_definition"
    else
        item_metadata=$(rest_call get "workspaces/$workspace_id/items?type=$item_type" "value[?displayName=='$item_name'] | [0].{description: description, displayName: displayName, type: type}" "json" | tr -d '\r')
        if [ -z "$item_metadata" ]; then
            log "Item $item_name of type $item_type was not found in the workspace."
            return 1
        fi
        log "Saving item metadata..."
        store_item_metadata "$folder" "$item_name" "$item_type" "$item_metadata"
    fi
}

store_item_metadata(){
    local folder=$1
    local item_name=$2
    local item_type=$3
    local item_metadata=$4
    local output_folder="$folder/$item_name.$item_type"
    mkdir -p "$output_folder"
    platform_file=$(cat <<EOF
{
  "\$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
  "metadata": $item_metadata,
  "config": {
    "version": "2.0",
    "logicalId": "00000000-0000-0000-0000-000000000000"
  }
}
EOF
)
    echo "$platform_file" | jq '.' > "$output_folder/.platform"
    log "Item metadata saved to $output_folder" "success"
}

get_item_definition(){
    local workspace_id=$1
    local item_name=$2
    local item_type=$3

    # Get item id
    item_id=$(get_item_id "$workspace_id" "$item_name" "$item_type")
    if [ -z "$item_id" ]; then
        log "Item $item_name of type $item_type was not found in the workspace."
        return 1
    fi
    log "Found item '$item_name' with ID: '$item_id'"
    log "retrieving item definition for '$item_name'"
    # then get item definition
    # if itemType=Notebook then filter for format=ipynb
    if [ "$item_type" == "Notebook" ]; then
        uri="workspaces/$workspace_id/items/$item_id/getDefinition?format=ipynb"
    else
        uri="workspaces/$workspace_id/items/$item_id/getDefinition"
    fi
    response=$(curl -sSi -X POST -H "Authorization: Bearer $FABRIC_USER_TOKEN" "$FABRIC_API_BASEURL/$uri" --data "")
    response=$(return_operation_response "$response" "$item_name" "$item_type")

    echo "$response"
}

store_item_definition(){
    local folder=$1
    local item_name=$2
    local item_type=$3
    local definitionJson=$4
    local output_folder="$folder/$item_name.$item_type"
    mkdir -p "$output_folder"
    # for each path element in the item definition json
    # convert the base64 encoded content to a file
    # using the payloadType, payload and path elements
    # for part in $(echo "$definitionJson" | jq -r '.definition.parts[] | @base64'); do
    #     part=$(echo "$part" | base64 --decode)
    for part in $(echo "$definitionJson" | jq -r -c '.definition.parts[]'); do
        path=$(echo "$part" | jq -r -c '.path')
        payloadType=$(echo "$part" | jq -r -c '.payloadType')
        payload=$(echo "$part" | jq -r -c '.payload')
        log "Saving item definition part '$path' in '$output_folder'"
        if [ "$payloadType" == "InlineBase64" ]; then
            echo -n "$payload" | base64 -d > "$output_folder/$path"
        else
            echo -n "$payload" > "$output_folder/$path"
        fi
    done 
    log "Item definition saved to $output_folder" "success"
}

#-----------------------------
# Long running operations
#-----------------------------

return_operation_response() {
    local response="$1"
    local item_name="$2"
    local item_type="$3"

    status_code=$(echo "$response" | head -n 1 | cut -d' ' -f2)

    if [ "$status_code" != 202 ] && [ "$status_code" != 200 ]; then
        log "Failed to retrieve definition for item $item_name of type $item_type."
        log "Response: $response"
        return 1
    fi
    if [ "$status_code" == 200 ]; then
        response=$(echo "$response" | tail -n 1)
        echo "$response"
        return 0
    else
        location=$(echo "$response" | grep -i ^location: | cut -d: -f2- | sed 's/^ *\(.*\).*/\1/' | tr -d '\r')
        retry_after=$(echo "$response" | grep -i ^retry-after: | cut -d: -f2- | sed 's/^ *\(.*\).*/\1/' | tr -d '\r')
        response=$(long_running_operation_polling "$location" "$retry_after")
        if [ -z "$response" ]; then
            log "Failed to retrieve definition for item $item_name of type $item_type."
            return 1
        fi
    fi

    echo "$response"

}

# Function to poll a long running operation
long_running_operation_polling() {
    local uri=$1
    local retryAfter=$2
    local requestHeader="Authorization: Bearer $FABRIC_USER_TOKEN"

    log "Polling long running operation ID has been started with a retry-after time of $retryAfter seconds."

    while true; do
        operationState=$(curl -s -H "$requestHeader" "$uri")
        status=$(echo "$operationState" | jq -r '.status')

        if [[ "$status" == "NotStarted" || "$status" == "Running" ]]; then
            sleep 20
        else
            break
        fi
    done

    if [ "$status" == "Failed" ]; then
        log "The long running operation has been completed with failure. Error response: $(echo "$operationState" | jq '.')"
    else
        log "Operation successfully completed." "success"
        item=$(curl -s -H "$requestHeader" "$uri/result")
        echo "$item"
    fi
}

#------------------------------
# Item CRUD Operations
#------------------------------

# Function to create or update a workspace item
# This function takes a workspace ID, item name, item type, and folder as arguments
# It checks if the item already exists in the workspace and either creates or updates it accordingly
create_or_update_item() {
    local workspace_id=$1
    local item_folder="$2"

    platform_file="$item_folder/.platform"
    if [ ! -f "$platform_file" ]; then
        log "Item folder '$item_folder' does not contain a .platform file." "danger"
        exit 1
    fi

    item_name=$(jq -r '.metadata.displayName' "$platform_file")
    item_type=$(jq -r '.metadata.type' "$platform_file")
    if [ -z "$item_name" ] || [ -z "$item_type" ]; then
        log "Error: Item name or type not found in the .platform file."
        exit 1
    fi
    log "Platform file contains item '$item_name' of type $item_type"


    # check if the item already exists in the workspace
    item_id=$(get_item_id "$workspace_id" "$item_name" "$item_type")
    if [ -n "$item_id" ]; then
        log "Item $item_name of type $item_type already exists in the workspace and has item ID: $item_id.\nUpdating item..." "warning"
        returned_item=$(update_item "$workspace_id" "$item_id" "$item_name" "$item_type" "$item_folder")
    else
        log "Item $item_name of type $item_type does not exist in the workspace.\nCreating new item..." "info"
        returned_item=$(create_item "$workspace_id" "$item_name" "$item_type" "$item_folder")
    fi
}

create_item() {
    local workspace_id=$1
    local item_name=$2
    local item_type=$3
    local item_folder=$4
    # This function creates a new item in the workspace
    # It takes the workspace ID, item name, item type, and folder as arguments

    body=$(echo '{"displayName": "'"$item_name"'", "description": "", "type": "'"$item_type"'"}')

    returned_item=$(rest_call post "workspaces/$workspace_id/items" "" "json" "$body")
    item_id=$(echo "$returned_item" | jq -r '.id')
    if [ -z "$item_id" ]; then
        log "Failed to create item $item_name of type $item_type."
        return 1
    fi

    # if the item type has a definition then use the definition
    # count the number of files in item_folder that are not the .platform file
    file_count=$(find "$item_folder" -type f ! -name ".platform" | wc -l)
    if [ "$file_count" -gt 0 ]; then
        log "Updating item definition..." "info"
        returned_item=$(update_item_definition "$workspace_id" "$item_id" "$item_folder")
    fi
    echo "$returned_item"
}

update_item() {
    local workspace_id=$1
    local item_id=$2
    local item_name=$3
    local item_type=$4
    local item_folder=$5
    # This function updates an existing item in the workspace
    # It takes the workspace ID, item id, item name, item type, and folder as arguments

    # check if the item folder contains a definition file
    # if the item type is DataPipeline then the defintion file name is 'pipeline-content.json'
    # if the item type is Notebook then the defintion file name is 'notebook-content.ipynb' or 'notebook-content.py'
    platform_file="$item_folder/.platform"

    # if the item type requires definition files then make sure they exist 
    if   [ "$item_type" == "Notebook" ] && [ ! -f "$item_folder/notebook-content.ipynb" ]; then
         definition_file="$item_folder/notebook-content.py"
    elif [ "$item_type" == "Notebook" ] && [ ! -f "$item_folder/notebook-content.py" ]; then
            definition_file="$item_folder/notebook-content.ipynb"
    elif [ "$item_type" == "DataPipeline" ]; then
            definition_file="$item_folder/pipeline-content.json"
    fi

    definition_file_exists=false
    if ([ "$item_type" == "Notebook" ] || [ "$item_type" == "DataPipeline" ]) && [ ! -f "$definition_file" ]; then
        log "No definition file found in the item folder '$item_folder', only metadata will be updated." "warning"
    elif [ "$item_type" == "Notebook" ] || [ "$item_type" == "DataPipeline" ]; then
        definition_file_exists=true
        log "Definition file found in the item folder '$item_folder'."
    fi

    if [ $definition_file_exists == "true" ]; then
        returned_item=$(update_item_definition "$workspace_id" "$item_id" "$item_folder")
    else
        # update only metadata
        item_metadata=$(jq -r ".metadata | {displayName, description}" "$platform_file")
        returned_item=$(rest_call patch "workspaces/$workspace_id/items/$item_id" "" "json" "$item_metadata")
    fi

    if [ -z "$returned_item" ]; then
        log "Failed to update item $item_name of type $item_type."
        return 1
    fi
    if [ $definition_file_exists == "true" ]; then
        log "Item $item_name of type $item_type was updated with definition." "success"
    else
        log "Item $item_name of type $item_type was updated." "success"
    fi

    echo "$returned_item"
}

update_item_definition() {
    local workspace_id=$1
    local item_id=$2
    local item_folder="$3"

    # construct body or curl call by listing all files in the item folder
    # for every file, get the base64 encoded content
    # and create a part object with the path, payloadType and payload
    shopt -s lastpipe
    find "$item_folder" -type f | while IFS= read -r file; do
        path=$(basename "$file")
        payloadType="InlineBase64"
        # Deal with Open Darwin's version of base64
        # which does not support the -w option
        if [[ "$(uname)" == "Darwin" ]]; then # Mac OSX
            payload=$(base64 < "$file" | tr -d '\n' | tr -d '\r')  
        else
            payload=$(base64 -w 0 "$file")
        fi
        
        file_extension="${path##*.}"
        if [ $file_extension == "ipynb" ]; then
            format="ipynb"
        fi
        echo -n '{"path" : "'"$path"'", "payloadType" : "'"$payloadType"'", "payload" : "'"$payload"'"}' >> parts.json
    done

    parts=$(cat parts.json | jq -s '.' | tr -d '\r' | tr -d '\n')
    if [ -z $format ]; then
        echo -n '{"definition" : {"parts" : ' $parts "}}" > definition.json
    else
        echo -n '{"definition" : {"parts" : '$parts', "format" : "'$format'"}}' > definition.json
    fi
    shopt -u lastpipe

    uri="workspaces/$workspace_id/items/$item_id/updateDefinition?updateMetadata=true"
    item_name=$(jq -r '.metadata.displayName' "$item_folder/.platform")
    item_type=$(jq -r '.metadata.type' "$item_folder/.platform")
    response=$(curl -sSi -X POST -H "Authorization: Bearer $FABRIC_USER_TOKEN" "$FABRIC_API_BASEURL/$uri" -H "Content-Type: application/json" --data "@definition.json")
    response=$(return_operation_response "$response" "$item_name" "$item_type")
    rm -f parts.json
    rm -f definition.json

    echo "$response"
}