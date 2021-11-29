#!/bin/bash 

# Change this to your desired location.
location="eastus"

echo "Enter prefix for azure resources:"
read resource_prefix

unique_str=`echo $RANDOM | tr '[0-9]' '[a-z]'`

resource_group="${resource_prefix}-${unique_str}-rg"
work_space_name="${resource_prefix}-${unique_str}-ws"
storage_account_name="${resource_prefix}${unique_str}sa"
sql_admin_login_user="${resource_prefix}_sql_admin"
password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
spark_pool="SparkPool1"

# create resource group
echo "Creating resource group: $resource_group"
az group create --name $resource_group --location $location

echo "Creating storage account: $storage_account_name"
az storage account create -n $storage_account_name -g $resource_group -l $location --sku Standard_LRS --kind StorageV2 \
--enable-hierarchical-namespace true --access-tier Hot

echo "Creating storage container: root"
connection_string=`az storage account show-connection-string -g $resource_group -n $storage_account_name -o tsv`

az storage container create \
    --account-name $storage_account_name \
    --name root \
    --connection-string $connection_string

#upload sample data file.
echo "Uploading sample data file."
az storage blob upload -f "../data/country_list.csv" -c root/source --account-name $storage_account_name 

echo "Creating synapse workspace: $work_space_name"
az synapse workspace create --name $work_space_name \
                            --resource-group $resource_group \
                            --storage-account $storage_account_name \
                            --file-system root \
                            --sql-admin-login-user $sql_admin_login_user \
                            --sql-admin-login-password $password \
                            --location $location

echo "Adding role permissions for storage account"
identity=`az synapse workspace show --name $work_space_name --resource-group $resource_group --query "identity.principalId" -o tsv`
echo "Workspace identity: $identity"
scope_id=`az storage account show -g $resource_group -n $storage_account_name --query "id" -o tsv`
az role assignment create --assignee-object-id $identity --role "Storage Blob Data Contributor" --scope "$scope_id"


#### Create Firewall Rule ####
echo "Creating firewall to allow acces."
az synapse workspace firewall-rule create --resource-group $resource_group \
                                          --workspace-name $work_space_name \
                                          --name allow-all \
                                          --start-ip-address 0.0.0.0 \
                                          --end-ip-address 255.255.255.255


echo "Creating spark pool: $spark_pool"  
az synapse spark pool create --name $spark_pool --workspace-name $work_space_name --resource-group $resource_group \
--spark-version 2.4 --node-count 3 --node-size Small

#  Upload orchestrator notebook
echo "Uploading orchestrator notebook."
az synapse notebook import --file '@../OrchestratorNotebook.ipynb' --name OrchestratorNotebook --workspace-name $work_space_name

# Update linked service name in dataset
sed "s/TEMP-WORKSPACE-NAME/$work_space_name/" ../csv_dataset.json > ../temp_csv_dataset.json

#Update default value for staorage account parameter.
sed "s/TEMP-STORAGE-ACCOUNT/$storage_account_name/" ../pipeline.json > ../temp_pipeline.json

#Create dataset
echo "Creating synapse dataset."
az synapse dataset create --workspace-name $work_space_name --name csv_dataset --file '@../temp_csv_dataset.json'

#Create synapse pipeline
echo "Creating synapse pipeline."
az synapse pipeline create --workspace-name $work_space_name --name DataProcessPipeline --file '@../temp_pipeline.json'

# uploading packages
echo "Uploading workspace packages."
az synapse workspace-package upload-batch --workspace-name $work_space_name -s ../packages/

echo "Applying packages to your spark pool."
az synapse spark pool update --name $spark_pool --workspace-name $work_space_name --resource-group $resource_group --package-action Add --package md5-0.0.1-py3-none-any.whl data_filter-0.0.1-py3-none-any.whl

echo "Note: Your sql admin password is: $password"
echo "Finished creating all the required resources."