#!/bin/bash
set -o errexit

#######################################################
# Deploys all necessary azure and Fabric resources
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

## Environment variables
environment_name="$ENVIRONMENT_NAME"
tenant_id="$TENANT_ID"
subscription_id="$SUBSCRIPTION_ID"
resource_group_name="$RESOURCE_GROUP_NAME"
base_name="$BASE_NAME"
## Service Principal details
client_id="$APP_CLIENT_ID"
client_secret="$APP_CLIENT_SECRET"
# GIT integration details
git_organization_name="$GIT_ORGANIZATION_NAME"
git_project_name="$GIT_PROJECT_NAME"
git_repository_name="$GIT_REPOSITORY_NAME"
git_branch_name="$GIT_BRANCH_NAME"
# Workspace admin variables
fabric_workspace_admin_sg_name="$FABRIC_WORKSPACE_ADMIN_SG_NAME"
# Fabric Capacity variables
existing_fabric_capacity_name="$EXISTING_FABRIC_CAPACITY_NAME"
fabric_capacity_admins="$FABRIC_CAPACITY_ADMINS"
deploy_fabric_items="$DEPLOY_FABRIC_ITEMS"

## KeyVault secret variables
appinsights_connection_string_name="appinsights-connection-string"

# Git directory name for syncing Fabric workspace items
fabric_workspace_directory="/fabric/workspace"

# Fabric bearer token variables, set globally
fabric_bearer_token=""
fabric_api_endpoint="https://api.fabric.microsoft.com/v1"

# Fabric related variables
adls_gen2_shortcut_name="sc-adls-main"
adls_gen2_shortcut_path="Files"

# Azure DevOps pipelines to be deleted
azdo_pipeline_ci_qa="pl-ci-qa"
azdo_pipeline_ci_qa_cleanup="pl-ci-qa-cleanup"
azdo_pipeline_ci_publish_artifacts="pl-ci-publish-artifacts"

set_global_azdo_config() {
  # Set the global Azure DevOps (AzDo) configuration
  az devops configure --defaults organization="https://dev.azure.com/$git_organization_name" project="$git_project_name"
}

cleanup_terraform_resources() {
  local original_directory=$(pwd)
  cd "$1" || exit

  user_principal_type=$(az account show --query user.type -o tsv)
  if [[ $user_principal_type == "user" ]]; then
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
  else
    create_fabric_capacity=false
  fi

  echo "[Info] Switching to terraform '$environment_name' workspace."
  terraform workspace select -or-create=true "$environment_name"

  terraform init
  terraform destroy \
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

  cd "$original_directory"
}

set_bearer_token() {
  fabric_bearer_token=$(az account get-access-token \
    --resource "https://login.microsoftonline.com/${tenant_id}" \
    --query accessToken \
    --scope "https://analysis.windows.net/powerbi/api/.default" \
    -o tsv)
}

delete_connection() {
  # Function to delete a connection if it exists
  connection_id=$1
  delete_connection_url="$fabric_api_endpoint/connections/$connection_id"

  response=$(curl -s -X DELETE -H "Authorization: Bearer $fabric_bearer_token" "$delete_connection_url")

  if [[ -z $response ]]; then
    echo "[Info] Connection '$connection_id' deleted successfully."
  else
    echo "[Error] Failed to delete connection '$connection_id'."
    echo "[Error] $response"
  fi
}

cleanup_terraform_files() {
  # List and delete .terraform directories
  echo "[Info] Listing Terraform state directory that will be deleted:"
  find . -type d -name "${environment_name}" -path "*/terraform.tfstate.d/*"
  find . -type d -name "${environment_name}" -path "*/terraform.tfstate.d/*" -exec rm -rf {} + 2>/dev/null
  echo "[Info] Listing '.terraform' directory that will be deleted:"
  find . -type d -name ".terraform"
  find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null
  echo "[Info] Terraform directories deleted successfully."

  # List and delete specific Terraform files
  echo "[Info] Listing Terraform lock file that will be deleted:"
  find . -type f -name ".terraform.lock.hcl"
  find . -type f -name ".terraform.lock.hcl" -exec rm -f {} + 2>/dev/null
  echo "[Info] Terraform lock file deleted successfully."
}

cleanup_azdo_pipeline_files() {
  # List and delete Azure DevOps pipeline files
  echo "[Info] Listing Azure DevOps pipeline files that will be deleted:"
  find ./devops -maxdepth 1 -type f -name "*.yml"
  find ./devops -maxdepth 1 -type f -name "*.yml" -exec rm -f {} + 2>/dev/null
  echo "[Info] Azure DevOps pipeline files deleted successfully."
}

get_connection_id_by_name() {
  connection_name=$1
  list_connection_url="$fabric_api_endpoint/connections"
  response=$(curl -s -X GET -H "Authorization: Bearer $fabric_bearer_token" -H "Content-Type: application/json" "$list_connection_url" )
  connection_id=$(echo "$response" | jq -r --arg name "$connection_name" '.value[] | select(.displayName == $name) | .id')
  echo "$connection_id"
}

get_azdo_pipeline_id () {
  local pipeline_name=$1
  local pipeline_output=$(az pipelines list --query "[?name=='$pipeline_name']" --output json)
  local pipeline_id=$(echo "$pipeline_output" | jq -r '.[0].id')
  echo "$pipeline_id"
}

delete_azdo_pipeline() {
  local pipeline_name=$1
  local pipeline_id=$(get_azdo_pipeline_id "$pipeline_name")

  if [[ -z "$pipeline_id" || "$pipeline_id" == "null" ]]; then
    echo "[Info] No AzDo pipeline with name '$pipeline_name' found."
  else
    az pipelines delete --id "$pipeline_id" --yes 1>/dev/null
    echo "[Info] Deleted pipeline '$pipeline_name' (Pipeline ID: '$pipeline_id')"
  fi
}

echo "[Info] ############ STARTING CLEANUP STEPS############"

echo "[Info] ############ Destroy terraform resources ############"
cleanup_terraform_resources "./infrastructure/terraform"
echo "[Info] ############ Terraform resources destroyed############"

echo "[Info] Setting up fabric bearer token ############"
set_bearer_token

echo "[Info] ############ ADLS Gen2 connection deletion ############"
# Deriving ADLS Gen2 connection name instead of relying on Terraform output for idempotency
adls_gen2_connection_name="conn-adls-st${base_name//[-_]/}${environment_name}"

adls_gen2_connection_id=$(get_connection_id_by_name "$adls_gen2_connection_name")

if [[ -z $adls_gen2_connection_id ]]; then
  echo "[Warning] No Fabric connection with name '$adls_gen2_connection_name' found, skipping deletion."
else
  echo "[Info] Fabric Connection details: '$adls_gen2_connection_name' ($adls_gen2_connection_id)"
  delete_connection "$adls_gen2_connection_id"
fi

echo "[Info] ############ Cleanup Terraform Intermediate files (state, lock etc.,) ############"
cleanup_terraform_files

echo "[Info] ############ Deleting AzDo Pipelines ###########"
set_global_azdo_config

delete_azdo_pipeline "$azdo_pipeline_ci_qa"
delete_azdo_pipeline "$azdo_pipeline_ci_qa_cleanup"
delete_azdo_pipeline "$azdo_pipeline_ci_publish_artifacts"

echo "[Info] ############ Cleanup AzDo Pipeline files ('/devops/*.yml) ############"
cleanup_azdo_pipeline_files

echo "[Info] ############ FINISHED INFRA CLEANUP ############"
