#!/bin/bash 

set -o errexit
set -o nounset
# set -o xtrace # For debugging


DEPLOYMENT_PREFIX=${DEPLOYMENT_PREFIX:-}
if [ -z "$DEPLOYMENT_PREFIX" ]
then
    default_prefix="syndyn"  # synapse dynamic modules
    echo "Enter deployment prefix for azure resources (or press enter key to keep the default: $default_prefix):"
    read -r DEPLOYMENT_PREFIX
    if [ -z "$DEPLOYMENT_PREFIX" ]; then
        DEPLOYMENT_PREFIX=$default_prefix
        echo "No deployment prefix [DEPLOYMENT_PREFIX] specified. Using default: $DEPLOYMENT_PREFIX"
    fi
fi

AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
if [ -z "$AZURE_SUBSCRIPTION_ID" ]
then
    default_azure_subscription_id=$(az account show --output json | jq -r '.id')
    echo "Enter your azure subscription Id (or press enter key to keep the default: $default_azure_subscription_id):"
    read -r AZURE_SUBSCRIPTION_ID
    if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
        AZURE_SUBSCRIPTION_ID=$default_azure_subscription_id
        echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified. Using default: $AZURE_SUBSCRIPTION_ID"
    fi
fi

AZURE_RESOURCE_GROUP_LOCATION=${AZURE_RESOURCE_GROUP_LOCATION:-}
if [ -z "$AZURE_RESOURCE_GROUP_LOCATION" ]
then 
    default_location="eastus"
    echo "Enter resource group location (or press enter key to keep the default as $default_location):"
    read -r AZURE_RESOURCE_GROUP_LOCATION
    if [ -z "$AZURE_RESOURCE_GROUP_LOCATION" ]; then
        AZURE_RESOURCE_GROUP_LOCATION=$default_location
        echo "No Azure subscription id [AZURE_RESOURCE_GROUP_LOCATION] specified. Using default: $AZURE_RESOURCE_GROUP_LOCATION"
    fi
fi


unique_str=$(echo $RANDOM | tr '0-9' 'a-z')

AZURE_RESOURCE_GROUP_NAME="${DEPLOYMENT_PREFIX}-${unique_str}-rg"
WORK_SPACE_NAME="${DEPLOYMENT_PREFIX}-${unique_str}-ws"
STORAGE_ACCOUNT_NAME="${DEPLOYMENT_PREFIX}${unique_str}sa"
SQL_ADMIN_LOGIN_USER="${DEPLOYMENT_PREFIX}_sql_admin"
SQL_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1 | tr '[:upper:]' '[:lower:]')!
SPARK_POOL="SparkPool1"
IP_ADDRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')

# create resource group
echo "Creating resource group: $AZURE_RESOURCE_GROUP_NAME"
az group create --name "$AZURE_RESOURCE_GROUP_NAME" --location "$AZURE_RESOURCE_GROUP_LOCATION"

echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create -n "$STORAGE_ACCOUNT_NAME" -g "$AZURE_RESOURCE_GROUP_NAME" -l "$AZURE_RESOURCE_GROUP_LOCATION" --sku Standard_LRS --kind StorageV2 \
--enable-hierarchical-namespace true --access-tier Hot

echo "Creating storage container: root"
connection_string=$(az storage account show-connection-string -g "$AZURE_RESOURCE_GROUP_NAME" -n "$STORAGE_ACCOUNT_NAME" -o tsv)

az storage container create \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --name root \
    --connection-string "$connection_string"

#upload sample data file.
echo "Uploading sample data file."
az storage blob upload -f "../data/country_list.csv" -c root/source --account-name "$STORAGE_ACCOUNT_NAME"

echo "Creating synapse workspace: $WORK_SPACE_NAME"
az synapse workspace create --name "$WORK_SPACE_NAME" \
                            --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
                            --storage-account "$STORAGE_ACCOUNT_NAME" \
                            --file-system root \
                            --sql-admin-login-user "$SQL_ADMIN_LOGIN_USER" \
                            --sql-admin-login-password "$SQL_ADMIN_PASSWORD" \
                            --location "$AZURE_RESOURCE_GROUP_LOCATION"

echo "Adding role permissions for storage account"
identity=$(az synapse workspace show --name "$WORK_SPACE_NAME" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --query "identity.principalId" -o tsv)
echo "Workspace identity: $identity"
scope_id=$(az storage account show -g "$AZURE_RESOURCE_GROUP_NAME" -n "$STORAGE_ACCOUNT_NAME" --query "id" -o tsv)
az role assignment create --assignee-object-id "$identity" --role "Storage Blob Data Contributor" --scope "$scope_id"


#### Create Firewall Rule ####
echo "Creating firewall to allow acces from your client ip ($IP_ADDRESS)."
az synapse workspace firewall-rule create --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
                                          --workspace-name "$WORK_SPACE_NAME" \
                                          --name allow-all \
                                          --start-ip-address "$IP_ADDRESS" \
                                          --end-ip-address "$IP_ADDRESS"


echo "Creating spark pool: $SPARK_POOL"  
az synapse spark pool create --name $SPARK_POOL --workspace-name "$WORK_SPACE_NAME" --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
--spark-version 2.4 --node-count 3 --node-size Small

#  Upload orchestrator notebook
echo "Uploading orchestrator notebook."
az synapse notebook import --file '@../OrchestratorNotebook.ipynb' --name OrchestratorNotebook --workspace-name "$WORK_SPACE_NAME"

# Update linked service name in dataset
sed "s/TEMP-WORKSPACE-NAME/$WORK_SPACE_NAME/" ../csv_dataset.json > ../temp_csv_dataset.json

#Update default value for storage account parameter.
sed "s/TEMP-STORAGE-ACCOUNT/$STORAGE_ACCOUNT_NAME/" ../pipeline.json > ../temp_pipeline.json

#Update storage account for linked service.
sed "s/TEMP-STORAGE-ACCOUNT/$STORAGE_ACCOUNT_NAME/" ../linked_service.json > ../temp_linked_service.json

#Create dataset
echo "Creating synapse dataset."
az synapse dataset create --workspace-name "$WORK_SPACE_NAME" --name csv_dataset --file '@../temp_csv_dataset.json'

#Create synapse pipeline
echo "Creating synapse pipeline."
az synapse pipeline create --workspace-name "$WORK_SPACE_NAME" --name DataProcessPipeline --file '@../temp_pipeline.json'

#Create linked service
echo "Creating linked service for storage account"
az synapse linked-service create --file '@../temp_linked_service.json' --name adls-linkedservice --workspace-name "$WORK_SPACE_NAME"

# uploading packages
echo "Uploading workspace packages."
az synapse workspace-package upload-batch --workspace-name "$WORK_SPACE_NAME" -s ../packages/

echo "Applying packages to your spark pool."
az synapse spark pool update --name "$SPARK_POOL" \
                             --workspace-name "$WORK_SPACE_NAME" \
                             --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
                             --package-action Add --package md5-0.0.1-py3-none-any.whl data_filter-0.0.1-py3-none-any.whl

echo "Note: Your sql admin password is: $SQL_ADMIN_PASSWORD"
echo "Finished creating all the required resources."