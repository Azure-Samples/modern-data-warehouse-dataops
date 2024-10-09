#!/bin/bash

#######################################################
# Deploys all necessary azure and Fabric resources
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

source .env

## Environment variables
base_name="$TF_VAR_base_name"
location="$TF_VAR_location"
adls_gen2_connection_id="$ALDS_GEN2_CONNECTION_ID"
tenant_id="$FABRIC_TENANT_ID"

# Variable set based on Terraform output
tf_storage_account_name=""
tf_storage_container_name=""
tf_storage_account_url=""

# Fabric bearer token variables, set globally
fabric_bearer_token=""
fabric_api_endpoint="https://api.fabric.microsoft.com/v1"

# Fabric related variables
# fabric_workspace_name="ws-$base_name"
# onelake_name="onelake"
# lakehouse_name="lh_main"
alds_gen2_shortcut_name="sc_adls_gen2_main"
alds_gen2_shortcut_path="Files"
# environment_name="env_$base_name"
# environment_desc="Default Fabric environment for '$base_name' project"
# lakehouse_desc="Lakehouse for '$base_name' project"
# notebook_names=("nb-city-safety" "nb-covid-data")
# pipeline_names=("pl-covid-data")

deploy_terraform_resources() {
    cd "$1" || exit

    #user_principal_name=$(az account show --query user.name -o tsv)
    user_principal_type=$(az account show --query user.type -o tsv)
    if [[ "$user_principal_type" == "user" ]]; then use_cli="true"; else use_cli="false"; fi
    echo "use_cli is ${use_cli}"


    terraform init
    terraform apply \
        -auto-approve \
        -var "use_cli=$use_cli" #\
        # -var "base_name=$base_name" \
        # -var "location=$location" \
        # -var "fabric_capacity_admin=$TF_VAR_fabric_capacity_admin" \
        # -var "fabric_workspace_admins=$TF_VAR_fabric_workspace_admin" \
        # -var "rg_name=$TF_VAR_rg_name" \
        # -var "git_organization_name=$TF_VAR_git_organization_name" \
        # -var "git_project_name=$TF_VAR_git_project_name" \
        # -var "git_repository_name=$TF_VAR_git_repository_name" \
        # -var "git_branch_name=$TF_VAR_git_branch_name" \
        # -var "git_directory_name=$TF_VAR_git_directory_name"

    tf_storage_container_name=$(terraform output --raw storage_container_name)
    tf_storage_account_url=$(terraform output --raw storage_account_primary_dfs_endpoint)
    workspace_name=$(terraform output --raw workspace_name)
    workspace_id=$(terraform output --raw workspace_id)
    lakehouse_id=$(terraform output --raw lakehouse_id)
    environment_name=$(terraform output --raw workspace_name)
}

# function get_tenant_id() {
#     tenant_id=$(az account show --query 'tenantId' -o tsv)
#     if [ -z "$tenant_id" ]; then
#         echo "Failed to retrieve tenant ID. Make sure you are logged in with 'az login'." >&2
#         return 1
#     else
#         echo "$tenant_id"
#     fi
# }

function set_bearer_token() {
    # tenant_id=get_tenant_id
    fabric_bearer_token=$(az account get-access-token \
        --resource "https://login.microsoftonline.com/${tenant_id}" \
        --query accessToken \
        --scope "https://analysis.windows.net/powerbi/api/.default" \
        -o tsv)
}

# function get_capacity_id() {
#     capacity_name="$1"
#     response=$(curl -s -X GET -H "Authorization: Bearer $fabric_bearer_token" "$fabric_api_endpoint/capacities")
#     capacity_id=$(echo "${response}" | jq -r --arg var "$capacity_name" '.value[] | select(.displayName == $var) | .id')
#     echo "$capacity_id"
# }

# function get_workspace_id() {
#     workspace_name=$1
#     get_workspaces_url="$fabric_api_endpoint/workspaces"
#     workspaces=$(curl -s -H "Authorization: Bearer $fabric_bearer_token" "$get_workspaces_url" | jq -r '.value')
#     workspace=$(echo "$workspaces" | jq -r --arg name "$workspace_name" '.[] | select(.displayName == $name)')
#     workspace_id=$(echo "$workspace" | jq -r '.id')
#     echo "$workspace_id"
# }

# function get_workspace_identity() {
#     workspace_id=$1
#     get_workspace_url="$fabric_api_endpoint/workspaces/$workspace_id"
#     workspace=$(curl -s -H "Authorization: Bearer $fabric_bearer_token" "$get_workspace_url")
#     identity=$(echo "$workspace" | jq -r '.workspaceIdentity.applicationId')
#     echo "$identity"
# }

# function create_workspace(){
#     local workspace_name="$1"
#     local capacity_id="$2"

#     jsonPayload=$(cat <<EOF
# {
#     "DisplayName": "$workspace_name",
#     "capacityId": "${capacity_id}",
#     "description": "Workspace $workspace_name",
# }
# EOF
# )

#     curl -s -X POST "$fabric_api_endpoint/workspaces" \
#         -o /dev/null \
#         -H "Authorization: Bearer $fabric_bearer_token" \
#         -H "Content-Type: application/json" \
#         -d "${jsonPayload}"
# }

# function provision_workspace_identity() {
#     workspace_id=$1
#     provision_identity_url="$fabric_api_endpoint/workspaces/$workspace_id/provisionIdentity"
#     provision_identity_body={}
#     response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $fabric_bearer_token" -d "$provision_identity_body" "$provision_identity_url")
#     echo "$response"
# }

# function get_item_by_name_type() {
#     workspace_id=$1
#     item_type=$2
#     item_name=$3

#     get_items_url="$fabric_api_endpoint/workspaces/$workspace_id/items"
#     items=$(curl -s -X GET -H "Authorization: Bearer $fabric_bearer_token" "$get_items_url" | jq -r '.value')
#     item=$(echo "$items" | jq -r --arg name "$item_name" --arg type "$item_type" '.[] | select(.displayName == $name and .type == $type)')
#     item_id=$(echo "$item" | jq -r '.id')
#     echo "$item_id"
# }

# function lakehouse_payload() {
#     display_name=$1
#     description=$2
#     cat <<EOF
# {
#     "displayName": "$display_name",
#     "description": "$description",
#     "type": "Lakehouse"
# }
# EOF
# }

# function notebook_payload() {
#     display_name=$1
#     payload=$2
#     cat <<EOF
# {
#     "displayName": "$display_name",
#     "type": "Notebook",
#     "definition" : {
#         "format": "ipynb",
#         "parts": [
#             {
#                 "path": "artifact.content.ipynb",
#                 "payload": "$payload",
#                 "payloadType": "InlineBase64"
#             }
#         ]
#     }
# }
# EOF
# }

# function data_pipeline_payload() {
#     display_name=$1
#     description=$2
#     payload=$3
#     cat <<EOF
# {
#     "displayName": "$display_name",
#     "description": "$description",
#     "type":"DataPipeline",
#     "definition" : {
#         "parts" : [
#             {
#                 "path": "pipeline-content.json",
#                 "payload": "${payload}",
#                 "payloadType": "InlineBase64"
#             }
#         ]
#     }
# }
# EOF
# }

# function create_item() {
#     workspace_id=$1
#     item_type=$2
#     display_name=$3
#     description=$4
#     payload=$5
#     create_item_url="$fabric_api_endpoint/workspaces/$workspace_id/items"
#     case "$item_type" in
#         "Lakehouse")
#             create_item_body=$(lakehouse_payload "$display_name" "$description")
#             ;;
#         "Notebook")
#             create_item_body=$(notebook_payload "$display_name" "$payload")
#             ;;
#         "DataPipeline")
#             create_item_body=$(data_pipeline_payload "$display_name" "$description" "$payload")
#             ;;
#         *)
#             echo "[E] Invalid item type '$item_type'."
#             ;;
#     esac

#     response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $fabric_bearer_token" -d "$create_item_body" "$create_item_url")
#     if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
#         item_id=$(echo "$response" | jq -r '.id // empty')
#         if [ -n "$item_id" ]; then
#             echo "[I] Created $item_type '$display_name' ($item_id) successfully."
#         else
#             echo "[E] $item_type '$display_name' creation failed."
#             echo "[E] $response"
#         fi
#     else
#         sleep 10
#         item_id=$(get_item_by_name_type "$workspace_id" "$item_type" "$display_name")
#         echo "[I] Created $item_type '$display_name' ($item_id) successfully."
#     fi
# }

# function add_workspace_admin() {
#     workspace_id=$1
#     group_name=$2
#     add_admin_url="$fabric_api_endpoint/workspaces/$workspace_id/roleAssignments"
#     group_id=$(az ad group show --group "$group_name" --query id -o tsv)
#     add_admin_body=$(cat <<EOF
# {
#     "principal": {
#         "id": "$group_id",
#         "type": "Group"
#     },
#     "role": "Admin"
# }
# EOF
# )
#     response=$(curl -s -X POST -H "Authorization: Bearer $fabric_bearer_token" -H "Content-Type: application/json" -d "$add_admin_body" "$add_admin_url")
#     workspace_role_assignment_id=$(echo "$response" | jq -r '.id')
#     if [[ -n "$workspace_role_assignment_id" ]] && [[ "$workspace_role_assignment_id" != "null" ]]; then
#         echo "[I] Added security group '$group_name' as admin of the workspace."
#     else
#         error_code=$(echo "$response" | jq -r '.errorCode')
#         if [[ "$error_code" = "PrincipalAlreadyHasWorkspaceRolePermissions" ]]; then
#             echo "[W] Security group '$group_name' already has a role assigned in the workspace. Please review it manually."
#         else
#             echo "[E] Adding security group '$group_name' as admin of the workspace failed."
#             echo "[E] $response"
#         fi
#     fi
# }

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

# function get_environment_id() {
#     workspace_id=$1
#     environment_name=$2
#     get_environment_url="$fabric_api_endpoint/workspaces/$workspace_id/environments"
#     environments=$(curl -s -H "Authorization : Bearer $fabric_bearer_token" "$get_environment_url" | jq -r '.value') 
#     environment=$(echo "$environments" | jq -r --arg name "$environment_name" '.[] | select(.displayName == $name)')
#     environment_id=$(echo "$environment" | jq -r '.id')
#     echo "$environment_id"
# }
    
# function create_environment() {
#     workspace_id=$1
#     environment_name=$2
#     environment_desc=$3
#     create_environment_url="$fabric_api_endpoint/workspaces/$workspace_id/environments"
#     create_environment_body=$(cat <<EOF
# {
#     "displayName": "$environment_name",
#     "description": "$environment_desc"
# }
# EOF
# )
#     response=$(curl -s -X POST -H "Authorization: Bearer $fabric_bearer_token" -H "Content-Type: application/json" -d "$create_environment_body" "$create_environment_url")
#     environment_id=$(echo "$response" | jq -r '.id')
#     if [[ -n "$environment_id" ]] && [[ "$environment_id" != "null" ]]; then
#         echo "[I] Created environment '$environment_name' ($environment_id) successfully."
#     else
#         echo "[E] Environment '$environment_name' creation failed."
#         echo "[E] $response"
#     fi
# }

echo "[I] ############ START ############"
echo "[I] ############ Deploying terraform resources ############"
deploy_terraform_resources "./terraform"

echo "[I] ############ Terraform resources deployed, setting up fabric bearer token ############"
set_bearer_token

# fabric_capacity_id=$(get_capacity_id "$tf_fabric_capacity_name")
# if [[ -z "$fabric_capacity_id" ]]; then
#     echo "[E] Capacity '$tf_fabric_capacity_name' not found. Please verify the capacity name passed."
#     exit 1
# fi

# echo "[I] Fabric capacity is '$tf_fabric_capacity_name' ($fabric_capacity_id)"

# echo "[I] ############ Workspace Creation ############"
# fabric_workspace_id=$(get_workspace_id "$fabric_workspace_name")
# if [[ -n "$fabric_workspace_id" ]]; then
#     echo "[W] Workspace '$fabric_workspace_name' ($fabric_workspace_id) already exists. Please verify the attached capacity manually."
# else
#     create_workspace "$fabric_workspace_name" "$fabric_capacity_id"
#     workspace_id=$(get_workspace_id "$fabric_workspace_name")
#     echo "[I] Created workspace '$fabric_workspace_name' ($workspace_id)"
# fi

# echo "[I] ############ Lakehouse Creation ############"
# lakehouse_id=$(get_item_by_name_type "$fabric_workspace_id" "Lakehouse" "$lakehouse_name")
# if [[ -n "$lakehouse_id" ]]; then
#     echo "[I] Lakehouse $lakehouse_name ($lakehouse_id) already exists."
# else
#     create_item "$fabric_workspace_id" "Lakehouse" "$lakehouse_name" "$lakehouse_desc" ""
#     lakehouse_id=$(get_item_by_name_type "$fabric_workspace_id" "Lakehouse" "$lakehouse_name")
# fi

# echo "[I] ############ Provisioning Workspace Identity ############"
# workspace_identity_app_id=$(get_workspace_identity "$fabric_workspace_id")
# if [[ -n "$workspace_identity_app_id" ]]; then
#     echo "[I] Workspace identity '$workspace_identity_app_id' already provisioned."
# else
#     provision_workspace_identity "$fabric_workspace_id"
# fi

# echo "[I] ############ Adding entra security group as workspace admin ############"
# add_workspace_admin "$fabric_workspace_id" "$tf_security_group_name"

echo "[I] ############ ALDS Gen2 Shortcut Creation ############"
if [[ -z "$adls_gen2_connection_id" ]]; then
    echo "[W] ADLS Gen2 connection ID not provided. Skipping ALDS Gen2 connection creation."
else
    if if_shortcut_exist "$workspace_id" "$lakehouse_id" "$alds_gen2_shortcut_name" "$alds_gen2_shortcut_path"; then
        echo "[W] Shortcut '$alds_gen2_shortcut_name' already exists, please review it manually."
    else
        adls_gen2_connection_object=$(get_adls_gen2_connection_object "$adls_gen2_connection_id" "$tf_storage_account_url" "$tf_storage_container_name")
        create_shortcut \
            "$fabric_workspace_id" \
            "$lakehouse_id" \
            "$alds_gen2_shortcut_name" \
            "$alds_gen2_shortcut_path" \
            "$adls_gen2_connection_object"
    fi
fi

# echo "[I] ############ Fabric Environment Creation ############"
# environment_id=$(get_environment_id "$fabric_workspace_id" "$environment_name")
# if [[ -n "$environment_id" ]]; then
#     echo "[I] Environment '$environment_name' ($environment_id) already exists."
# else
#     create_environment "$fabric_workspace_id" "$environment_name" "$environment_desc"
#     environment_id=$(get_environment_id "$fabric_workspace_id" "$environment_name")
#     echo "[I] Created environment '$environment_name' ($environment_id)"
# fi

echo "[I] ############ Uploading packages to Environment ############"
if [[ "$use_cli" == "true" ]]; then
    python3 ./../scripts/setup_fabric_environment.py --workspace_name "$workspace_name" --environment_name "$environment_name" --bearer_token "$fabric_bearer_token"
else
    echo "[I] Service Principal does not support loading environments, skipping."
fi
