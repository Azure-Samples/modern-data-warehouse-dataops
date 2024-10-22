#!/bin/bash
set -o errexit

#######################################################
# Deploys all necessary azure and Fabric resources
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

source ./.env

## Environment variables
base_name="$base_name"
location="$location"
adls_gen2_connection_id="$ADLS_GEN2_CONNECTION_ID"
tenant_id="$tenant_id"
subscription_id="$subscription_id"
client_id="$client_id"
client_secret="$client_secret"
fabric_capacity_admin="$fabric_capacity_admin"
fabric_workspace_admins="$fabric_workspace_admins"
rg_name="$rg_name"
fabric_capacity_id=$(echo "$fabric_capacity_id" | tr '[:upper:]' '[:lower:]' )
git_organization_name="$git_organization_name"
git_project_name="$git_project_name"
git_repository_name="$git_repository_name"
git_branch_name="$git_branch_name"
git_directory_name="$git_directory_name"

# Variable set based on Terraform output
tf_storage_container_name=""
tf_storage_account_url=""
tf_workspace_name=""
tf_workspace_id=""
tf_lakehouse_id=""
tf_environment_name=""

# Fabric bearer token variables, set globally
fabric_bearer_token=""
fabric_api_endpoint="https://api.fabric.microsoft.com/v1"

# Fabric related variables
alds_gen2_shortcut_name="sc_adls_gen2_main"
alds_gen2_shortcut_path="Files"

deploy_terraform_resources() {
    cd "$1" || exit

    user_principal_type=$(az account show --query user.type -o tsv)
    if [[ "$user_principal_type" == "user" ]]; then
        use_cli="true"
        use_msi="false"
    else
        use_cli="false"
        msi=$(az account show --query user.assignedIdentityInfo -o tsv)
        if [[ -z "${msi}" ]]; then
            use_msi=false;
        else 
            use_msi=true;
        fi
    fi
    echo "[I] use_cli is ${use_cli}"
    echo "[I] use_msi is ${use_msi}"
    echo "[I] executing as client_id ${client_id}"

    if [[ -z "${fabric_capacity_id}" ]]; then
        create_fabric_capacity=true
        echo "[I] Variable fabric_capacity_id was empty, a new Fabric capacity will be created"
    else
        create_fabric_capacity=false
        echo "[I] Variable fabric_capacity_id was NOT empty, the provided Fabric capacity will be used"
    fi


    terraform init
    terraform apply \
        -auto-approve \
        -var "use_cli=$use_cli" \
        -var "use_msi=$use_msi" \
        -var "tenant_id=$tenant_id" \
        -var "subscription_id=$subscription_id" \
        -var "client_id=$client_id" \
        -var "client_secret=$client_secret" \
        -var "base_name=$base_name" \
        -var "location=$location" \
        -var "fabric_capacity_admin=$fabric_capacity_admin" \
        -var "fabric_workspace_admins=$fabric_workspace_admins" \
        -var "rg_name=$rg_name" \
        -var "create_fabric_capacity=$create_fabric_capacity" \
        -var "fabric_capacity_id=$fabric_capacity_id" \
        -var "git_organization_name=$git_organization_name" \
        -var "git_project_name=$git_project_name" \
        -var "git_repository_name=$git_repository_name" \
        -var "git_branch_name=$git_branch_name" \
        -var "git_directory_name=$git_directory_name" 

    tf_storage_container_name=$(terraform output --raw storage_container_name)
    tf_storage_account_url=$(terraform output --raw storage_account_primary_dfs_endpoint)
    tf_workspace_name=$(terraform output --raw workspace_name)
    tf_workspace_id=$(terraform output --raw workspace_id)
    tf_lakehouse_id=$(terraform output --raw lakehouse_id)
    tf_environment_name=$(terraform output --raw environment_name)
}

function set_bearer_token() {
    fabric_bearer_token=$(az account get-access-token \
        --resource "https://login.microsoftonline.com/${tenant_id}" \
        --query accessToken \
        --scope "https://analysis.windows.net/powerbi/api/.default" \
        -o tsv)
}

function get_adls_gen2_connection_object() {
    connection_id=$1
    location=$2
    subpath=$3
    cat <<EOF
{
    "adlsGen2": {
        "connectionId": "$connection_id",
        "location": "$location",
        "subpath": "$subpath"
    }
}
EOF
}

function if_shortcut_exist(){
    workspace_id=$1
    item_id=$2
    shortcut_name=$3
    shortcut_path=$4
    get_shortcut_url="$fabric_api_endpoint/workspaces/$workspace_id/items/$item_id/shortcuts/$shortcut_path/$shortcut_name"
    sc_name=$(curl -s -X GET -H "Authorization: Bearer $fabric_bearer_token" "$get_shortcut_url" | jq -r '.name')
    if [[ -n "$sc_name" ]] && [[ "$sc_name" != "null" ]]; then
        return 0
    else
        return 1
    fi
}

function create_shortcut() {
    workspace_id=$1
    item_id=$2
    shortcut_name=$3
    shortcut_path=$4
    target=$5
    create_shortcut_url="$fabric_api_endpoint/workspaces/$workspace_id/items/$item_id/shortcuts"

    create_shortcut_body=$(cat <<EOF
{
    "name": "$shortcut_name",
    "path": "$shortcut_path",
    "target": $target
}
EOF
)   
    response=$(curl -s -X POST -H "Authorization: Bearer $fabric_bearer_token" -H "Content-Type: application/json" -d "$create_shortcut_body" "$create_shortcut_url")
    sc_name=$(echo "$response" | jq -r '.name')
    if [[ -n "$sc_name" ]] && [[ "$sc_name" != "null" ]]; then
        echo "[I] Shortcut '$shortcut_name' created successfully."
    else
        echo "[E] Shortcut '$shortcut_name' creation failed."
        echo "[E] $response"
    fi
}

echo "[I] ############ START ############"
echo "[I] ############ Deploying terraform resources ############"
deploy_terraform_resources "./terraform"

echo "[I] ############ Terraform resources deployed, setting up fabric bearer token ############"
set_bearer_token

echo "[I] ############ ALDS Gen2 Shortcut Creation ############"
if [[ -z "$adls_gen2_connection_id" ]]; then
    echo "[W] ADLS Gen2 connection ID not provided. Skipping ALDS Gen2 connection creation."
else
    if if_shortcut_exist "$tf_workspace_name" "$tf_lakehouse_id" "$alds_gen2_shortcut_name" "$alds_gen2_shortcut_path"; then
        echo "[W] Shortcut '$alds_gen2_shortcut_name' already exists, please review it manually."
    else
        adls_gen2_connection_object=$(get_adls_gen2_connection_object "$adls_gen2_connection_id" "$tf_storage_account_url" "$tf_storage_container_name")
        create_shortcut \
            "$tf_workspace_id" \
            "$tf_lakehouse_id" \
            "$alds_gen2_shortcut_name" \
            "$alds_gen2_shortcut_path" \
            "$adls_gen2_connection_object"
    fi
fi

echo "[I] ############ Uploading packages to Environment ############"
if [[ "$use_cli" == "true" ]]; then
    python3 ./../scripts/setup_fabric_environment.py --workspace_name "$tf_workspace_name" --environment_name "$tf_environment_name" --bearer_token "$fabric_bearer_token"
else
    echo "[I] Service Principal login does not support loading environments, skipping."
fi