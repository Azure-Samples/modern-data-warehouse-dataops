#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

#######################################################
# Deploys all necessary azure and Fabric resources
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

# Source common functions
. ./scripts/common.sh

# Validate required environment variables
validate_required_vars \
    "ENVIRONMENT_NAME" \
    "TENANT_ID" \
    "SUBSCRIPTION_ID" \
    "RESOURCE_GROUP_NAME" \
    "BASE_NAME" \
    "APP_CLIENT_ID" \
    "APP_CLIENT_SECRET" \
    "GIT_ORGANIZATION_NAME" \
    "GIT_PROJECT_NAME" \
    "GIT_REPOSITORY_NAME" \
    "GIT_BRANCH_NAME" \
    "FABRIC_WORKSPACE_ADMIN_SG_NAME"

# Validate required commands
validate_commands "az" "terraform" "jq" "curl"

## Environment variables
environment_name="${ENVIRONMENT_NAME}"
tenant_id="${TENANT_ID}"
subscription_id="${SUBSCRIPTION_ID}"
resource_group_name="${RESOURCE_GROUP_NAME}"
base_name="${BASE_NAME}"
## Service Principal details
client_id="${APP_CLIENT_ID}"
client_secret="${APP_CLIENT_SECRET}"
# GIT integration details
git_organization_name="${GIT_ORGANIZATION_NAME}"
git_project_name="${GIT_PROJECT_NAME}"
git_repository_name="${GIT_REPOSITORY_NAME}"
git_branch_name="${GIT_BRANCH_NAME}"
# Workspace admin variables
fabric_workspace_admin_sg_name="${FABRIC_WORKSPACE_ADMIN_SG_NAME}"
# Fabric Capacity variables
existing_fabric_capacity_name="${EXISTING_FABRIC_CAPACITY_NAME}"
fabric_capacity_admins="${FABRIC_CAPACITY_ADMINS}"
deploy_fabric_items="${DEPLOY_FABRIC_ITEMS}"

## KeyVault secret variables
appinsights_connection_string_name="appinsights-connection-string"

# Git directory name for syncing Fabric workspace items
fabric_workspace_directory="/fabric/workspace"

# Variable set based on Terraform output
tf_storage_account_name=""
tf_storage_container_name=""
tf_storage_account_url=""
tf_keyvault_name=""
tf_keyvault_uri=""
tf_workspace_name=""
tf_workspace_id=""
tf_lakehouse_name=""
tf_lakehouse_id=""
tf_environment_name=""
tf_environment_id=""
tf_setup_notebook_name=""
tf_setup_notebook_id=""
tf_standardize_notebook_name=""
tf_standardize_notebook_id=""
tf_transform_notebook_name=""
tf_transform_notebook_id=""
tf_appinsights_connection_string_value=""
tf_fabric_workspace_admin_sg_principal_id=""
tf_azdo_variable_group_name=""
tf_azdo_variable_group_kv_name=""
tf_azdo_service_connection_name=""

# Fabric bearer token variables, set globally
fabric_bearer_token=""
fabric_api_endpoint="https://api.fabric.microsoft.com/v1"

# Fabric related variables
adls_gen2_shortcut_name="sc-adls-main"
adls_gen2_shortcut_path="Files"

deploy_terraform_resources() {
  cd "$1" || exit
  principal_type="$2"

  if [[ $principal_type == "user" ]]; then
    use_cli="true"
    use_msi="false"
  else
    use_cli="false"
    msi=$(az account show --query user.assignedIdentityInfo -o tsv)
    if [[ -z ${msi} ]]; then
      use_msi=false
    else
      use_msi=true
    fi
  fi
  echo "[Info] 'use_cli' is '${use_cli}'"
  echo "[Info] 'use_msi' is '${use_msi}'"
  echo "[Info] 'client_id' is '${client_id}'"
  echo "[Info] 'deploy_fabric_items' is '${deploy_fabric_items}'"

  if [[ -z ${existing_fabric_capacity_name} ]]; then
    create_fabric_capacity=true
    echo "[Info] Variable 'EXISTING_FABRIC_CAPACITY_NAME' is empty, a new Fabric capacity will be created."
  else
    create_fabric_capacity=false
    echo "[Info] Variable 'EXISTING_FABRIC_CAPACITY_NAME' is NOT empty, the provided Fabric capacity will be used."
  fi

  # Select or create the terraform workspace
  echo "[Info] Switching to terraform '$environment_name' workspace."
  terraform workspace select -or-create=true "$environment_name"

  terraform init
  terraform apply \
    -auto-approve \
    -var "use_cli=$use_cli" \
    -var "use_msi=$use_msi" \
    -var "environment_name=$environment_name" \
    -var "tenant_id=$tenant_id" \
    -var "subscription_id=$subscription_id" \
    -var "resource_group_name=$resource_group_name" \
    -var "base_name=$base_name" \
    -var "client_id=$client_id" \
    -var "client_secret=$client_secret" \
    -var "fabric_workspace_admin_sg_name=$fabric_workspace_admin_sg_name" \
    -var "create_fabric_capacity=$create_fabric_capacity" \
    -var "fabric_capacity_name=$existing_fabric_capacity_name" \
    -var "fabric_capacity_admins=$fabric_capacity_admins" \
    -var "git_organization_name=$git_organization_name" \
    -var "git_project_name=$git_project_name" \
    -var "git_repository_name=$git_repository_name" \
    -var "git_branch_name=$git_branch_name" \
    -var "git_directory_name=$fabric_workspace_directory" \
    -var "fabric_adls_shortcut_name=$adls_gen2_shortcut_name" \
    -var "kv_appinsights_connection_string_name=$appinsights_connection_string_name" \
    -var "deploy_fabric_items=$deploy_fabric_items"

  tf_storage_account_name=$(terraform output --raw storage_account_name)
  tf_storage_container_name=$(terraform output --raw storage_container_name)
  tf_storage_account_url=$(terraform output --raw storage_account_primary_dfs_endpoint)
  tf_keyvault_name=$(terraform output --raw keyvault_name)
  tf_keyvault_uri=$(terraform output --raw keyvault_uri)
  tf_workspace_name=$(terraform output --raw workspace_name)
  tf_workspace_id=$(terraform output --raw workspace_id)
  tf_lakehouse_name=$(terraform output --raw lakehouse_name)
  tf_lakehouse_id=$(terraform output --raw lakehouse_id)
  tf_environment_id=$(terraform output --raw environment_id)
  tf_environment_name=$(terraform output --raw environment_name)
  tf_setup_notebook_name=$(terraform output --raw setup_notebook_name)
  tf_setup_notebook_id=$(terraform output --raw setup_notebook_id)
  tf_standardize_notebook_name=$(terraform output --raw standardize_notebook_name)
  tf_standardize_notebook_id=$(terraform output --raw standardize_notebook_id)
  tf_transform_notebook_name=$(terraform output --raw transform_notebook_name)
  tf_transform_notebook_id=$(terraform output --raw transform_notebook_id)
  tf_appinsights_connection_string_value=$(terraform output --raw appinsights_connection_string)
  tf_fabric_workspace_admin_sg_principal_id=$(terraform output --raw fabric_workspace_admin_sg_principal_id)
  tf_azdo_variable_group_name=$(terraform output --raw azdo_variable_group_name)
  tf_azdo_variable_group_kv_name=$(terraform output --raw azdo_variable_group_kv_name)
  tf_azdo_service_connection_name=$(terraform output --raw azdo_service_connection_name)
}

function set_bearer_token() {
  fabric_bearer_token=$(az account get-access-token \
    --resource "https://login.microsoftonline.com/${tenant_id}" \
    --query accessToken \
    --scope "https://analysis.windows.net/powerbi/api/.default" \
    -o tsv)
}

function create_adls_gen2_connection() {
  display_name=$1
  adls_gen2_server=$2
  adls_gen2_path=$3

  connectivity_type="ShareableCloud"
  privacy_level="Organizational"
  create_connection_url="$fabric_api_endpoint/connections"

  server_parameter=$(
    cat <<EOF
{
  "dataType": "text",
  "name": "server",
  "value": "$adls_gen2_server"
}
EOF
  )

  path_parameter=$(
    cat <<EOF
{
  "dataType": "text",
  "name": "path",
  "value": "$adls_gen2_path"
}
EOF
  )

  connection_details_body=$(
    cat <<EOF
{
  "type": "AzureDataLakeStorage",
  "creationMethod": "AzureDataLakeStorage",
  "parameters": [$server_parameter, $path_parameter]
}
EOF
  )

  credential_details_body=$(
    cat <<EOF
{
  "credentialType": "WorkspaceIdentity"
}
EOF
  )

  credential_details_body=$(
    cat <<EOF
{
  "credentials": $credential_details_body,
  "singleSignOnType": "None",
  "connectionEncryption": "NotEncrypted",
  "skipTestConnection": false,
}
EOF
  )

  create_connection_body=$(
    cat <<EOF
{
  "connectionDetails": $connection_details_body,
  "connectivityType": "$connectivity_type",
  "credentialDetails": $credential_details_body,
  "displayName": "$display_name",
  "privacyLevel": "$privacy_level",
}
EOF
  )

  response=$(curl -s -X POST -H "Authorization: Bearer $fabric_bearer_token" -H "Content-Type: application/json" -d "$create_connection_body" "$create_connection_url")
  connection_id=$(echo "$response" | jq -r '.id')

  if [[ -n $connection_id ]] && [[ $connection_id != "null" ]]; then
    echo "$connection_id"
  else
    echo "[Error] Connection '$adls_gen2_connection_name' creation failed."
    echo "[Error] Request Body: $create_connection_body"
    echo "[Error] Response: $response"
  fi
}

get_connection_id_by_name() {
  connection_name=$1
  list_connection_url="$fabric_api_endpoint/connections"

  response=$(curl -s -X GET -H "Authorization: Bearer $fabric_bearer_token" -H "Content-Type: application/json" "$list_connection_url" )
  connection_id=$(echo "$response" | jq -r --arg name "$connection_name" '.value[] | select(.displayName == $name) | .id')
  echo "$connection_id"
}

function add_connection_role_assignment() {
  connection_id=$1
  security_group_id=$2
  add_connection_role_assignment_url="$fabric_api_endpoint/connections/$connection_id/roleAssignments"

  role_assignment_principal=$(
    cat <<EOF
{
  "id": "$security_group_id",
  "type": "Group"
}
EOF
  )

  add_connection_role_assignment_body=$(
    cat <<EOF
{
  "principal": $role_assignment_principal,
  "role": "Owner"
}
EOF
  )

  response=$(curl -s -X POST -H "Authorization: Bearer $fabric_bearer_token" -H "Content-Type: application/json" -d "$add_connection_role_assignment_body" "$add_connection_role_assignment_url")
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

function if_shortcut_exist() {
  workspace_id=$1
  item_id=$2
  shortcut_name=$3
  shortcut_path=$4
  get_shortcut_url="$fabric_api_endpoint/workspaces/$workspace_id/items/$item_id/shortcuts/$shortcut_path/$shortcut_name"
  sc_name=$(curl -s -X GET -H "Authorization: Bearer $fabric_bearer_token" "$get_shortcut_url" | jq -r '.name')
  if [[ -n $sc_name ]] && [[ $sc_name != "null" ]]; then
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

  create_shortcut_body=$(
    cat <<EOF
{
  "name": "$shortcut_name",
  "path": "$shortcut_path",
  "target": $target
}
EOF
  )
  response=$(curl -s -X POST -H "Authorization: Bearer $fabric_bearer_token" -H "Content-Type: application/json" -d "$create_shortcut_body" "$create_shortcut_url")
  sc_name=$(echo "$response" | jq -r '.name')
  if [[ -n $sc_name ]] && [[ $sc_name != "null" ]]; then
    echo "[Info] Shortcut '$shortcut_name' created successfully."
  else
    echo "[Error] Shortcut '$shortcut_name' creation failed."
    echo "[Error] $response"
  fi
}

echo "[Info] ############ STARTING INFRA DEPLOYMENT ############"
echo "[Info] ############ Deploying terraform resources ############"
user_principal_type=$(az account show --query user.type -o tsv)

deploy_terraform_resources "./infrastructure/terraform" "$user_principal_type"

echo "[Info] ############ Terraform resources deployed, setting up fabric bearer token ############"
set_bearer_token

echo "[Info] ############ ADLS Gen2 Cloud Connection Creation ############"
adls_gen2_connection_name="conn-adls-${tf_storage_account_name}"

adls_gen2_connection_id=$(get_connection_id_by_name "$adls_gen2_connection_name")

if [[ -n "$adls_gen2_connection_id" ]]; then
  echo "[Info] Fabric Connection with name '$adls_gen2_connection_name' ($adls_gen2_connection_id) already exists. Using it."
else
  adls_gen2_connection_id=$(create_adls_gen2_connection "$adls_gen2_connection_name" "${tf_storage_account_url%/}" "$tf_storage_container_name")
  echo "[Info] Fabric Connection details: '$adls_gen2_connection_name' ($adls_gen2_connection_id)"
  echo "[Info] ############ ADLS Gen2 Cloud Connection Created ############"
fi

add_connection_role_assignment "$adls_gen2_connection_id" "$tf_fabric_workspace_admin_sg_principal_id"

if [[ $user_principal_type == "user" ]] && [[ $deploy_fabric_items == "true" ]]; then
  echo "[Info] ############ ADLS Gen2 Shortcut Creation ############"
  if if_shortcut_exist "$tf_workspace_id" "$tf_lakehouse_id" "$adls_gen2_shortcut_name" "$adls_gen2_shortcut_path"; then
    echo "[Warning] Shortcut '$adls_gen2_shortcut_name' already exists, please review it manually."
  else
    adls_gen2_connection_object=$(get_adls_gen2_connection_object "$adls_gen2_connection_id" "$tf_storage_account_url" "$tf_storage_container_name")
    create_shortcut \
      "$tf_workspace_id" \
      "$tf_lakehouse_id" \
      "$adls_gen2_shortcut_name" \
      "$adls_gen2_shortcut_path" \
      "$adls_gen2_connection_object"
  fi
else
  echo "[Warning] ############ Skipping ADLS Gen2 Shortcut Creation ############"
fi

if [[ $user_principal_type == "user" ]]; then
  echo "[Info] ############ Uploading config file and seed data ############"

  WORKSPACE_NAME=$tf_workspace_name \
  WORKSPACE_ID=$tf_workspace_id \
  LAKEHOUSE_NAME=$tf_lakehouse_name \
  LAKEHOUSE_ID=$tf_lakehouse_id \
  ADLS_GEN2_SHORTCUT_NAME=$adls_gen2_shortcut_name \
  RESOURCE_GROUP_NAME=$resource_group_name \
  KEYVAULT_NAME=$tf_keyvault_name \
  STORAGE_ACCOUNT_NAME=$tf_storage_account_name \
  STORAGE_CONTAINER_NAME=$tf_storage_container_name \
    bash -c "./../../scripts/upload_config_files.sh"
else
  echo "[Warning] ############ Skipping config file and seed data upload ############"
  echo "[Warning] Need to authenticate using the user context for config file and seed data upload. See README.md for more details."
fi

echo "[Info] ############ Uploading packages to Environment ############"
if [[ $deploy_fabric_items == "true" ]]; then
  cd "./../../scripts"
  python3 setup_fabric_environment.py --workspace_name "$tf_workspace_name" --environment_name "$tf_environment_name" --bearer_token "$fabric_bearer_token"
else
  echo "[Info] The Fabric environment is not created in higher environments, thus skipping package upload."
fi

echo "[Info] ############ FINISHED INFRA DEPLOYMENT ############"
