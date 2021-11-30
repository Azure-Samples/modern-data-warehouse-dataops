#!/bin/bash 

# Change this to your desired location.
DEFAULT_LOCATION="eastus"

echo "Enter deployment prefix for azure resources:"
read DEPLOYMENT_PREFIX

if [ -z "$DEPLOYMENT_PREFIX" ]; then
    echo "Prefix is required to create azure resources"
    exit 1
fi

echo "Enter your azure subscription Id(or press enter key to keep the default):"
read AZURE_SUBSCRIPTION_ID

echo "Enter resource group location(or press enter key to keep the default as $DEFAULT_LOCATION):"
read AZURE_RESOURCE_GROUP_LOCATION

# Login to Azure and select the subscription
if ! AZURE_USERNAME=$(az account show --query user.name); then
    echo "No Azure account logged in, now trying to log in."
    az login --output none    
fi

if [ ! -z "$AZURE_SUBSCRIPTION_ID" ]; then
    echo "Logged in as $AZURE_USERNAME, set the active subscription to \"$AZURE_SUBSCRIPTION_ID\""
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
else
    subscriptionId="$(az account show --query "id" --output tsv)"
    echo "Using $subscriptionId as your default subscription id."
fi

if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    echo "Using $DEFAULT_LOCATION as default location"
    AZURE_RESOURCE_GROUP_LOCATION=$DEFAULT_LOCATION
fi


unique_str=`echo $RANDOM | tr '[0-9]' '[a-z]'`

AZURE_RESOURCE_GROUP_NAME="${DEPLOYMENT_PREFIX}-${unique_str}-rg"
WORK_SPACE_NAME="${DEPLOYMENT_PREFIX}-${unique_str}-ws"
STORAGE_ACCOUNT_NAME="${DEPLOYMENT_PREFIX}${unique_str}sa"
SQL_ADMIN_LOGIN_USER="${DEPLOYMENT_PREFIX}_sql_admin"
SQL_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
SPARK_POOL="SparkPool1"

# create resource group
echo "Creating resource group: $AZURE_RESOURCE_GROUP_NAME"
az group create --name $AZURE_RESOURCE_GROUP_NAME --location $AZURE_RESOURCE_GROUP_LOCATION

echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create -n $STORAGE_ACCOUNT_NAME -g $AZURE_RESOURCE_GROUP_NAME -l $AZURE_RESOURCE_GROUP_LOCATION --sku Standard_LRS --kind StorageV2 \
--enable-hierarchical-namespace true --access-tier Hot

echo "Creating storage container: root"
connection_string=`az storage account show-connection-string -g $AZURE_RESOURCE_GROUP_NAME -n $STORAGE_ACCOUNT_NAME -o tsv`

az storage container create \
    --account-name $STORAGE_ACCOUNT_NAME \
    --name root \
    --connection-string $connection_string

#upload sample data file.
echo "Uploading sample data file."
az storage blob upload -f "../data/country_list.csv" -c root/source --account-name $STORAGE_ACCOUNT_NAME 

echo "Creating synapse workspace: $WORK_SPACE_NAME"
az synapse workspace create --name $WORK_SPACE_NAME \
                            --resource-group $AZURE_RESOURCE_GROUP_NAME \
                            --storage-account $STORAGE_ACCOUNT_NAME \
                            --file-system root \
                            --sql-admin-login-user $SQL_ADMIN_LOGIN_USER \
                            --sql-admin-login-password $SQL_ADMIN_PASSWORD \
                            --location $AZURE_RESOURCE_GROUP_LOCATION

echo "Adding role permissions for storage account"
identity=`az synapse workspace show --name $WORK_SPACE_NAME --resource-group $AZURE_RESOURCE_GROUP_NAME --query "identity.principalId" -o tsv`
echo "Workspace identity: $identity"
scope_id=`az storage account show -g $AZURE_RESOURCE_GROUP_NAME -n $STORAGE_ACCOUNT_NAME --query "id" -o tsv`
az role assignment create --assignee-object-id $identity --role "Storage Blob Data Contributor" --scope "$scope_id"


#### Create Firewall Rule ####
echo "Creating firewall to allow acces."
az synapse workspace firewall-rule create --resource-group $AZURE_RESOURCE_GROUP_NAME \
                                          --workspace-name $WORK_SPACE_NAME \
                                          --name allow-all \
                                          --start-ip-address 0.0.0.0 \
                                          --end-ip-address 255.255.255.255


echo "Creating spark pool: $SPARK_POOL"  
az synapse spark pool create --name $SPARK_POOL --workspace-name $WORK_SPACE_NAME --resource-group $AZURE_RESOURCE_GROUP_NAME \
--spark-version 2.4 --node-count 3 --node-size Small

#  Upload orchestrator notebook
echo "Uploading orchestrator notebook."
az synapse notebook import --file '@../OrchestratorNotebook.ipynb' --name OrchestratorNotebook --workspace-name $WORK_SPACE_NAME

# Update linked service name in dataset
sed "s/TEMP-WORKSPACE-NAME/$WORK_SPACE_NAME/" ../csv_dataset.json > ../temp_csv_dataset.json

#Update default value for staorage account parameter.
sed "s/TEMP-STORAGE-ACCOUNT/$STORAGE_ACCOUNT_NAME/" ../pipeline.json > ../temp_pipeline.json

#Create dataset
echo "Creating synapse dataset."
az synapse dataset create --workspace-name $WORK_SPACE_NAME --name csv_dataset --file '@../temp_csv_dataset.json'

#Create synapse pipeline
echo "Creating synapse pipeline."
az synapse pipeline create --workspace-name $WORK_SPACE_NAME --name DataProcessPipeline --file '@../temp_pipeline.json'

# uploading packages
echo "Uploading workspace packages."
az synapse workspace-package upload-batch --workspace-name $WORK_SPACE_NAME -s ../packages/

echo "Applying packages to your spark pool."
az synapse spark pool update --name $SPARK_POOL \
                             --workspace-name $WORK_SPACE_NAME \
                             --resource-group $AZURE_RESOURCE_GROUP_NAME \
                             --package-action Add --package md5-0.0.1-py3-none-any.whl data_filter-0.0.1-py3-none-any.whl

echo "Note: Your sql admin password is: $SQL_ADMIN_PASSWORD"
echo "Finished creating all the required resources."