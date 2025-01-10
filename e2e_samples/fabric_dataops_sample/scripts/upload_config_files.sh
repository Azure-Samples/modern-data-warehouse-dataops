#!/bin/bash
set -o errexit

config_template_file="./../../config/application.cfg.template"
config_file="./../../config/application.cfg"
lakehouse_ddls_yaml_file="./../../config/lakehouse_ddls.yaml"
seed_dim_date_file="./../../data/seed/dim_date.csv"
seed_dim_time_file="./../../data/seed/dim_time.csv"

workspace_name="$WORKSPACE_NAME"
workspace_id="$WORKSPACE_ID"
lakehouse_name="$LAKEHOUSE_NAME"
lakehouse_id="$LAKEHOUSE_ID"
adls_gen2_shortcut_name="$ADLS_GEN2_SHORTCUT_NAME"
resource_group_name="$RESOURCE_GROUP_NAME"
keyvault_name="$KEYVAULT_NAME"
storage_account_name="$STORAGE_ACCOUNT_NAME"
storage_container_name="$STORAGE_CONTAINER_NAME"

# create a configuration file from the template file and the parameters
create_config_file() {
  # read the config template file 'config/application.cfg.template' and replace the placeholders with the values from the parameters
  sed -e "s/<workspace-name>/$workspace_name/g" \
    -e "s/<workspace-id>/$workspace_id/g" \
    -e "s/<lakehouse-name>/$lakehouse_name/g" \
    -e "s/<lakehouse-id>/$lakehouse_id/g" \
    -e "s/<keyvault-name>/$keyvault_name/g" \
    -e "s/<adls-shortcut-name>/$adls_gen2_shortcut_name/g" \
    $config_template_file > $config_file

  echo "[Info] Configuration file created at '$config_file'."
}

# Create directories in the storage container
create_storage_directory() {
  directory_name=$1

  az storage fs directory create \
    --name $directory_name \
    --file-system $storage_container_name \
    --account-name "$storage_account_name" \
    --auth-mode login \
    --only-show-errors \
    --output none

  echo "[Info] Created directories '$directory_name' in container '$storage_container_name' of storage account '$storage_account_name'."
}

# upload file to the storage
upload_file() {
  config_file=$1
  target_filename=$2

  az storage fs file upload \
    --source $config_file \
    --path $target_filename \
    --file-system $storage_container_name \
    --account-name "$storage_account_name" \
    --auth-mode login \
    --overwrite true \
    --only-show-errors \
    --output none

  echo "[Info] Uploaded file '$target_filename' to storage account '$storage_account_name'."
}

echo "[Info] Creating 'application.cfg' file."
create_config_file

echo "[Info] Creating directories in the storage container."
create_storage_directory "/config"
create_storage_directory "/reference"

echo "[Info] Uploading configuration files to storage account."
upload_file "$config_file"              "/config/application.cfg"
upload_file "$lakehouse_ddls_yaml_file" "/config/lakehouse_ddls.yaml"
upload_file "$seed_dim_date_file"       "/reference/dim_date.csv"
upload_file "$seed_dim_time_file"       "/reference/dim_time.csv"
