#!/bin/bash

# Load environment variables from .env file
if [[ -f .env ]]; then
    echo "Loading environment variables from .env file"
    source .env
else
    echo ".env file not found!"
    exit 1
fi

# Function to deploy a Terraform module
deploy_module() {
    local module_path="$1"
    shift
    echo "Deploying module: ${module_path}"

    pushd "${module_path}" || exit 1

    terraform init || { echo "Terraform init failed"; exit 1; }
    terraform apply -auto-approve -var="region=${region}" -var="environment=${environment}" -var="subscription_id=${subscription_id}" "$@" || {
        echo "Terraform apply failed in ${module_path}"; exit 1;
    }

    popd || exit 1
}

# Deploy Azure Databricks Workspace
workspace_module_path="../modules/adb-workspace"
deploy_module "${workspace_module_path}" \
    -var="resource_group_name=${resource_group_name}"

# Capture Workspace Outputs
workspace_name=$(terraform -chdir="${workspace_module_path}" output -raw databricks_workspace_name)
workspace_resource_group=$(terraform -chdir="${workspace_module_path}" output -raw resource_group)
workspace_host_url=$(terraform -chdir="${workspace_module_path}" output -raw databricks_workspace_host_url)
workspace_id=$(terraform -chdir="${workspace_module_path}" output -raw databricks_workspace_id)

# Export workspace outputs as environment variables
export TF_VAR_databricks_workspace_name="${workspace_name}"
export TF_VAR_resource_group="${workspace_resource_group}"
export TF_VAR_databricks_workspace_host_url="${workspace_host_url}"
export TF_VAR_databricks_workspace_id="${workspace_id}"

# Deploy Metastore and Users
metastore_module_path="../modules/metastore-and-users"
deploy_module "${metastore_module_path}" \
    -var="resource_group=${workspace_resource_group}" \
    -var="databricks_workspace_name=${workspace_name}" \
    -var="databricks_workspace_host_url=${workspace_host_url}" \
    -var="databricks_workspace_id=${workspace_id}" \
    -var="metastore_name=${metastore_name}" \
    -var="aad_groups=${aad_groups}" \
    -var="account_id=${account_id}" \
    -var="prefix=${prefix}"

# Capture Metastore Outputs
metastore_id=$(terraform -chdir="${metastore_module_path}" output -raw metastore_id)
azurerm_storage_account_unity_catalog_id=$(terraform -chdir="${metastore_module_path}" output -json | jq -r '.azurerm_storage_account_unity_catalog.value.id')
azure_storage_account_name="${azurerm_storage_account_unity_catalog_id##*/}" # get storage account name
azurerm_databricks_access_connector_id=$(terraform -chdir="${metastore_module_path}" output -json | jq -r '.azurerm_databricks_access_connector_id.value')
databricks_groups=$(terraform -chdir="${metastore_module_path}" output -json databricks_groups)
databricks_users=$(terraform -chdir="${metastore_module_path}" output -json databricks_users)
databricks_sps=$(terraform -chdir="${metastore_module_path}" output -json databricks_sps)

# Export metastore outputs as environment variables
export TF_VAR_metastore_id="${metastore_id}"
export TF_VAR_azurerm_storage_account_unity_catalog_id="${azurerm_storage_account_unity_catalog_id}"
export TF_VAR_azure_storage_account_name="${azure_storage_account_name}"
export TF_VAR_azurerm_databricks_access_connector_id="${azurerm_databricks_access_connector_id}"
export TF_VAR_databricks_groups="${databricks_groups}"
export TF_VAR_databricks_users="${databricks_users}"
export TF_VAR_databricks_sps="${databricks_sps}"

# Deploy Unity Catalog
unity_catalog_module_path="../modules/adb-unity-catalog"
deploy_module "${unity_catalog_module_path}" \
    -var="environment=${environment}" \
    -var="subscription_id=${subscription_id}" \
    -var="databricks_workspace_host_url=${workspace_host_url}" \
    -var="databricks_workspace_id=${workspace_id}" \
    -var="metastore_id=${metastore_id}" \
    -var="azurerm_storage_account_unity_catalog_id=${azurerm_storage_account_unity_catalog_id}" \
    -var="azure_storage_account_name=${azure_storage_account_name}" \
    -var="azurerm_databricks_access_connector_id=${azurerm_databricks_access_connector_id}" \
    -var="databricks_groups=${databricks_groups}" \
    -var="databricks_users=${databricks_users}" \
    -var="databricks_sps=${databricks_sps}" \
    -var="aad_groups=${aad_groups}" \
    -var="account_id=${account_id}"

echo "All resources deployed successfully."