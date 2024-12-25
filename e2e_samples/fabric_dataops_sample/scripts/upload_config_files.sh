#!/bin/bash
set -o errexit

config_template_file="./../../config/application.cfg.template"
config_file="./../../config/application.cfg"
lakehouse_ddls_yaml_file="./../../config/lakehouse_ddls.yaml"
seed_dim_date_file="./../../data/seed/dim_date.csv"
seed_dim_time_file="./../../data/seed/dim_time.csv"


# create a configuration file from the template file and the parameters
function create_config_file() {
    workspace_name=$1
    workspace_id=$2
    lakehouse_name=$3
    lakehouse_id=$4
    keyvault_name=$5
    adls_shortcut_name=$6
    config_file=$7
    echo "Create configuration to config/application.cfg."
    # read the config template file config/application.cfg.template and replace the placeholders with the values from the parameters
    sed -e "s/<workspace-name>/$workspace_name/g" \
        -e "s/<workspace-id>/$workspace_id/g" \
        -e "s/<lakehouse-name>/$lakehouse_name/g" \
        -e "s/<lakehouse-id>/$lakehouse_id/g" \
        -e "s/<keyvault-name>/$keyvault_name/g" \
        -e "s/<adls-shortcut-name>/$adls_shortcut_name/g" \
        $config_template_file > $config_file

    echo "Configuration file created at $config_file."
}


# assign the role of "Storage Blob Data Contributor" to service principal
function assign_role_to_sp() {
    storage_account_id=$1
    resource_group_name=$2
    storage_container_name=$3
    client_id=$4
    sp_obj_id=$(az ad sp show --id $client_id --query id -o tsv)
    storage_account_name=$(az storage account show --ids $storage_account_id --query name -o tsv)

    az role assignment create \
        --role "Storage Blob Data Contributor" \
        --assignee-object-id "$sp_obj_id" \
        --assignee-principal-type "ServicePrincipal" \
        --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$resource_group_name/providers/Microsoft.Storage/storageAccounts/$storage_account_name/blobServices/default/containers/$storage_container_name" \
        --output none

    echo "Assigned "Storage Blob Data Contributor" role to service principal $sp_obj_id."
}

# create a storage container in the storage account and create directories /config and /reference
function create_storage_container() {
    storage_account_id=$1
    resource_group_name=$2
    storage_container_name=$3

    # get the storage account name from the storage account id
    storage_account_name=$(az storage account show --ids $storage_account_id --query name -o tsv)

    # create the folder /config in the storage container
    az storage fs directory create \
        -n "/config" \
        -f $storage_container_name \
        --account-name "$storage_account_name" \
        --auth-mode login \
        --output none

    # create the folder /reference in the storage container
    az storage fs directory create \
        -n "/reference" \
        -f $storage_container_name \
        --account-name "$storage_account_name" \
        --auth-mode login \
        --output none

    echo "Created directory /config and /reference in storage account $storage_account_name, container $storage_container_name, resource group $resource_group_name."
}

# upload file to the storage
function upload_file() {
    storage_account_id=$1
    resource_group_name=$2
    storage_container_name=$3
    config_file=$4
    target_filename=$5

    # get the storage account name from the storage account id
    storage_account_name=$(az storage account show --ids $storage_account_id --query name -o tsv)

    # upload the config file to the storage container
    az storage fs file upload \
        -s $config_file \
        -p $target_filename \
        -f $storage_container_name \
        --account-name "$storage_account_name" \
        --auth-mode login \
        --overwrite true \
        --output none

    echo "Uploaded file $target_filename to storage account $storage_account_name."
}

create_config_file \
    "$workspace_name" \
    "$workspace_id" \
    "$lakehouse_name" \
    "$lakehouse_id" \
    "$keyvault_name" \
    "$adls_gen2_shortcut_name" \
    "$config_file"

assign_role_to_sp \
    "$storage_account_id" \
    "$resource_group_name" \
    "$storage_container_name" \
    "$APP_CLIENT_ID"

create_storage_container \
    "$storage_account_id" \
    "$resource_group_name" \
    "$storage_container_name"

upload_file \
    "$storage_account_id" \
    "$resource_group_name" \
    "$storage_container_name" \
    "$config_file" \
    "/config/application.cfg"

upload_file \
    "$storage_account_id" \
    "$resource_group_name" \
    "$storage_container_name" \
    "$lakehouse_ddls_yaml_file" \
    "/config/lakehouse_ddls.yaml"

upload_file \
    "$storage_account_id" \
    "$resource_group_name" \
    "$storage_container_name" \
    "$seed_dim_date_file" \
    "/reference/dim_date.csv"

upload_file \
    "$storage_account_id" \
    "$resource_group_name" \
    "$storage_container_name" \
    "$seed_dim_time_file" \
    "/reference/dim_time.csv"
