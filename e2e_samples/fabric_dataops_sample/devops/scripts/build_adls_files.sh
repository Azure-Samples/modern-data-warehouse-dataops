#!/bin/bash
set -o errexit

config_template_file="config/application.cfg.template"
config_file="config/application.cfg"

function get_workspace_id() {
    access_token=$1
    workspace_name=$2

    echo "Get workspace ID for $workspace_name/$access_token"

    url="https://api.fabric.microsoft.com/v1/workspaces"
    response=$(curl -s -H "Authorization: Bearer $access_token" $url)

    echo "[Info] Workspaces: $response"

    workspace_id=$(echo $response | jq -r --arg workspace_name "$workspace_name" '.value[] | select(.displayName == $workspace_name) | .id')

    if [[ -z "$workspace_id" ]]; then
        echo "[Info] Workspace $workspace_name not found." >&2
        return 1
    fi

    export FABRIC_WORKSPACE_ID=$workspace_id
    echo "Workspace ID: $workspace_id"
    return 0
}

function get_lakehouse_id() {
    access_token=$1
    workspace_id=$2
    lakehouse_name=$3

    url="https://api.fabric.microsoft.com/v1/workspaces/$workspace_id/items"
    response=$(curl -s -H "Authorization: Bearer $access_token" $url)

    lakehouse_id=$(echo $response | jq -r --arg lakehouse_name "$lakehouse_name" '.value[] | select(.displayName == $lakehouse_name and .type == "Lakehouse") | .id')

    if [[ -z "$lakehouse_id" ]]; then
        echo "[Info] Lakehouse $lakehouse_name not found." >&2
        return 1
    fi

    export FABRIC_LAKEHOUSE_ID=$lakehouse_id
    echo "Lakehouse ID: $lakehouse_id"
    return 0
}

# Create a configuration file from the template file
function create_config_file() {
    workspace_name=$1
    workspace_id=$2
    lakehouse_name=$3
    lakehouse_id=$4
    keyvault_name=$5
    adls_shortcut_name=$6
    config_file=$7

    echo "Create configuration to config/application.cfg."

    # Read the config template file config/application.cfg.template and replace the placeholders with the actual values
    sed -e "s/<workspace-name>/$workspace_name/g" \
        -e "s/<workspace-id>/$workspace_id/g" \
        -e "s/<lakehouse-name>/$lakehouse_name/g" \
        -e "s/<lakehouse-id>/$lakehouse_id/g" \
        -e "s/<keyvault-name>/$keyvault_name/g" \
        -e "s/<adls-shortcut-name>/$adls_shortcut_name/g" \
        $config_template_file > $config_file

    echo "Configuration file created at $config_file."
}

get_workspace_id \
    "$FABRIC_BEARER_TOKEN"  \
    "$FABRIC_WORKSPACE_NAME" || { echo "Failed to get workspace_id"; exit 1; }

get_lakehouse_id  \
    "$FABRIC_BEARER_TOKEN" \
    "$FABRIC_WORKSPACE_ID" \
    "$FABRIC_LAKEHOUSE_NAME" || { echo "Failed to get lakehouse_id"; exit 1; }

create_config_file \
    "$FABRIC_WORKSPACE_NAME" \
    "$FABRIC_WORKSPACE_ID" \
    "$FABRIC_LAKEHOUSE_NAME" \
    "$FABRIC_LAKEHOUSE_ID" \
    "$KEYVAULT_NAME" \
    "$FABRIC_SHORTCUT_NAME" \
    "$config_file"

mkdir -p adls/config/
cp config/application.cfg adls/config/
cp config/lakehouse_ddls.yaml adls/config/

mkdir -p adls/reference/
cp -r data/seed/* adls/reference
