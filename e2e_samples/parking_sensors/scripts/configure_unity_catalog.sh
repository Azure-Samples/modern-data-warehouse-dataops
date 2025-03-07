#!/bin/bash

# Access granted under MIT Open Source License: https://en.wikipedia.org/wiki/MIT_License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, # and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions 
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.

set -o errexit
set -o pipefail
set -o nounset

# REQUIRED VARIABLES:
# SUBSCRIPTION_ID
# DATABRICKS_HOST
# DATABRICKS_KV_TOKEN
# ENVIRONMENT_NAME
# AZURE_LOCATION
# CATALOG_STG_ACCOUNT_NAME
# DATA_STG_ACCOUNT_NAME
# RESOURCE_GROUP_NAME
# MNG_RESOURCE_GROUP_NAME
# STG_CREDENTIAL_NAME
# CATALOG_EXT_LOCATION_NAME
# DATA_EXT_LOCATION_NAME
# CATALOG_NAME

. ./scripts/common.sh

# Create the databrickscfg file
cat <<EOL > ~/.databrickscfg
[DEFAULT]
host=$DATABRICKS_HOST
token=$DATABRICKS_KV_TOKEN
EOL

cat ~/.databrickscfg

log "Creating and configuring Unity Catalog for $ENVIRONMENT_NAME."

catalog_name=$CATALOG_NAME

###################################################################################################
# Functions.
###################################################################################################
create_db_external_location(){
    declare json_ext_location=$1
    declare external_location_name=$2

    # Check if the external location already exists
    log "External Location Name: $external_location_name" "Info"

    if [ -n "$external_location_name" ]; then
      if [ -z "$(databricks external-locations list | grep -w $external_location_name)" ]; then
          log "External location '$external_location_name' does not exist. Creating it now..." "Info"
          databricks external-locations create --json @$json_ext_location
          log "External location '$external_location_name' created successfully."
      else
          log "External location '$external_location_name' already exists. Skipping creation." "Info"
      fi
    else
      log "External location name is empty. Skipping creation." "Info"
    fi
}

create_db_catalog(){
    declare json_uc=$1
    declare catalog_name=$2

    log "Catalog Name: $catalog_name" "Info"
    # Check if the catalog already exists
    if [ -n "$catalog_name" ]; then
      if [ -z "$(databricks catalogs list | grep -w "$catalog_name")" ]; then
          log "Catalog '$catalog_name' does not exist. Creating it now..." "Info"
          databricks catalogs create --json @$json_uc
          log "Catalog '$catalog_name' created successfully."
      else
          log "Catalog '$catalog_name' already exists. Skipping creation." "Info"
      fi
    else
      log "Catalog name is empty. Skipping creation." "Info"
    fi
}

assign_rbac_role_to_msi(){
    declare role=$1
    declare scope=$2
    declare managed_identity_principal_id=$3
    declare stg_account_name=$4

    # Assign the role to the managed identity
    az role assignment create --assignee "$managed_identity_principal_id" --role "$role" --scope "$scope"
    log "Role '$role' assigned to managed identity '$managed_identity_name' for storage account '$stg_account_name'." "Info"
    sleep 60
}

###################################################################################################
# 1. Create a storage account with HNS enabled to serve as the physical storage for the catalog.
###################################################################################################
# Check if the catalog storage account already exists
existing_account=$(az storage account check-name --name $CATALOG_STG_ACCOUNT_NAME --query "nameAvailable" --output tsv)

if [ "$existing_account" == "true" ]; then
  log "Storage account '$CATALOG_STG_ACCOUNT_NAME' does not exist. Creating it now..."
  az storage account create \
    --name $CATALOG_STG_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $AZURE_LOCATION \
    --sku Standard_LRS \
    --kind StorageV2 \
    --hns true
  log "Storage account '$CATALOG_STG_ACCOUNT_NAME' created successfully with hierarchical namespace enabled." "Info"
else
  log "Storage account '$CATALOG_STG_ACCOUNT_NAME' already exists. Skipping creation." "Info"
fi

###################################################################################################
# 2. Create an ENV container for the environment catalog: dev/stg or prod.
###################################################################################################
# Check if the container already exists
container_name=$ENVIRONMENT_NAME
existing_container=$(az storage container exists --name $container_name --account-name $CATALOG_STG_ACCOUNT_NAME --auth-mode login --query "exists" --output tsv)

if [ "$existing_container" == "false" ]; then
  log "Container '$container_name' does not exist. Creating it now..." "Info"
  az storage container create \
    --name $container_name \
    --account-name $CATALOG_STG_ACCOUNT_NAME \
    --auth-mode login
  log "Container '$container_name' created successfully in storage account '$CATALOG_STG_ACCOUNT_NAME'." "Info"
else
  log "Container '$container_name' already exists. Skipping creation." "Info"
fi

###################################################################################################
# 3. Create a storage credential with DB Access Connector
###################################################################################################
json_storage_credential="./databricks/config/storage.credential.json"
# Create the JSON file
cat <<EOF > $json_storage_credential
{
  "name": "$STG_CREDENTIAL_NAME",
  "azure_managed_identity": {
    "access_connector_id": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/$MNG_RESOURCE_GROUP_NAME/providers/Microsoft.Databricks/accessConnectors/unity-catalog-access-connector"
  }
}
EOF

# Check if the storage credential already exists
echo "Credential Name: $STG_CREDENTIAL_NAME"
if [ -n "$STG_CREDENTIAL_NAME" ]; then
  if [ -z "$(databricks storage-credentials list | grep -w $STG_CREDENTIAL_NAME)" ]; then
    log "Storage credential '$STG_CREDENTIAL_NAME' does not exist. Creating it now..."
    databricks storage-credentials create --json @$json_storage_credential
    log "Storage credential '$STG_CREDENTIAL_NAME' created successfully." "Info"
  else
    log "Storage credential '$STG_CREDENTIAL_NAME' already exists. Skipping creation." "Info"
  fi
else
  log "Storage credential name is empty. Skipping creation." "Info"
fi

###################################################################################################
# 4. RBAC role assignment to the MSI for the storage account created in Step 1.
###################################################################################################
scope="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$CATALOG_STG_ACCOUNT_NAME"
access_connector_resource_id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$MNG_RESOURCE_GROUP_NAME/providers/Microsoft.Databricks/accessConnectors/unity-catalog-access-connector"

# Get the name of the MSI using the resource ID
managed_identity_name=$(az resource show --ids $access_connector_resource_id --query 'name' --output tsv)
log "Managed Identity Name: $managed_identity_name" "Info"
# Get the managed identity principal ID
managed_identity_principal_id=$(az resource show --ids $access_connector_resource_id --query 'identity.principalId' --output tsv)   
log "Managed Identity Principal ID: $managed_identity_principal_id" "Info"
# Assign the role to the managed identity
role="Storage Blob Data Contributor"
assign_rbac_role_to_msi "$role" "$scope" "$managed_identity_principal_id" "$CATALOG_STG_ACCOUNT_NAME" "Info"

###################################################################################################
# 5. RBAC role assignment to the MSI for the storage account that holds the data.
###################################################################################################
# Assign the role to the managed identity
scope="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$DATA_STG_ACCOUNT_NAME"
# Assign the role to the managed identity
role="Storage Blob Data Contributor"
assign_rbac_role_to_msi "$role" "$scope" "$managed_identity_principal_id" "$DATA_STG_ACCOUNT_NAME" "Info"	


###################################################################################################
# 6. Create the external location with the previously created storage credential - for the catalog
###################################################################################################
# Create the external location for the catalog
cat_json_ext_location="./databricks/config/catalog.external.location.json"
# Create the JSON file
cat <<EOF > $cat_json_ext_location
{
  "name": "$CATALOG_EXT_LOCATION_NAME",
  "url": "abfss://$container_name@$CATALOG_STG_ACCOUNT_NAME.dfs.core.windows.net",
  "credential_name": "$STG_CREDENTIAL_NAME"
}
EOF

create_db_external_location $cat_json_ext_location $CATALOG_EXT_LOCATION_NAME

###################################################################################################
# 7. Create the external location with the previously created storage credential - for the data
###################################################################################################
# Create the external location for the data
data_json_ext_location="./databricks/config/data.external.location.json"
# Create the JSON file
cat <<EOF > $data_json_ext_location
{
  "name": "$DATA_EXT_LOCATION_NAME",
  "url": "abfss://datalake@$DATA_STG_ACCOUNT_NAME.dfs.core.windows.net",
  "credential_name": "$STG_CREDENTIAL_NAME"
}
EOF

create_db_external_location $data_json_ext_location $DATA_EXT_LOCATION_NAME
###################################################################################################
# 8. Create the <DEV/STG/PROD> catalog with the previously created external location.
###################################################################################################
comment="Catalog for $catalog_name environment."

json_uc="./databricks/config/uc.json"
# Create the JSON file
cat <<EOF > $json_uc
{
  "name": "$catalog_name",
  "comment": "$comment",
  "storage_root": "abfss://$container_name@$CATALOG_STG_ACCOUNT_NAME.dfs.core.windows.net"
}
EOF

create_db_catalog $json_uc $catalog_name
