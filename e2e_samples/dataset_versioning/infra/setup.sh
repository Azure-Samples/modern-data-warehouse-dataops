#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging


while true; do
    echo "Enter the name for 'resource group', 'storage account', 'keyvault', and 'location', separated by spaces."
    echo -e "ex:\n    resourcegroup storageaccount kv-terraform-prime eastus \n"
    echo -e "Then, following resources will be created:"
    echo "    Resource Group: resourcegroup"
    echo "    Storage Account: storageaccount"
    echo "    Keyvault: kv-terraform-prime"
    echo "    Service Principal: sp-resourcegroup-Prime-tf"
    echo -e "\n"
    read -rp "Enter value: " RESOURCE_GROUP_NAME TF_STATE_STORAGE_ACCOUNT_NAME KEYVAULT_NAME LOCATION

    SP_NAME="sp-${RESOURCE_GROUP_NAME}-tf"
    TF_STATE_CONTAINER_NAME=terraform-state

    # Create the resource group
    if [ "$(az group exists --name "$RESOURCE_GROUP_NAME" --output tsv)" = false ]; then
        echo "Creating '${RESOURCE_GROUP_NAME}' resource group."
        az group create -n "$RESOURCE_GROUP_NAME" -l "$LOCATION" --tags iac=setup --output none
    fi

    # Create the storage account (hot storage)
    echo "Creating '${TF_STATE_STORAGE_ACCOUNT_NAME}' storage account."
    az storage account create -g "$RESOURCE_GROUP_NAME" -l "$LOCATION" \
    --name "${TF_STATE_STORAGE_ACCOUNT_NAME}" \
    --sku Standard_LRS \
    --encryption-services blob \
    --kind StorageV2 \
    --tags iac=setup \
    --output none

    # Retrieve the storage account key
    ACCOUNT_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP_NAME" --account-name "${TF_STATE_STORAGE_ACCOUNT_NAME}" --query [0].value --output tsv)

    # Create a storage container (for the Terraform State)
    az storage container create --name "$TF_STATE_CONTAINER_NAME" \
    --account-name "${TF_STATE_STORAGE_ACCOUNT_NAME}" \
    --account-key "$ACCOUNT_KEY" \
    --output none

    # Create an Azure KeyVault
    echo "Creating '${KEYVAULT_NAME}' keyvault."
    az keyvault create -g "$RESOURCE_GROUP_NAME" \
    -l "$LOCATION" --name "$KEYVAULT_NAME" \
    --tags iac=setup --output none

    # Store the Terraform State Storage Key into KeyVault
    echo "Storing tf state storage key to keyvault."
    az keyvault secret set --name tfstate-storage-key --value "$ACCOUNT_KEY" --vault-name "$KEYVAULT_NAME" --output none

    # Create Service Principal
    echo "Creating service principal scoped to '${RESOURCE_GROUP_NAME}' resource group."
    SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    ad=$(az ad sp create-for-rbac -n "$SP_NAME" --role Contributor --scopes /subscriptions/"$SUBSCRIPTION_ID"/resourceGroups/"$RESOURCE_GROUP_NAME" --query '[appId, password]' --output tsv)
    APP_ID=$(echo "${ad}" | head -1)
    SP_PASSWD=$(echo "${ad}" | tail -1)
    TENANT_ID=$(az ad sp show --id "$APP_ID" --query appOwnerTenantId --output tsv)

    # Store credentials to be used by Terraform
    echo "Storing Service Principal cred to keyvault."
    az keyvault secret set --name tf-subscription-id --value "$SUBSCRIPTION_ID" --vault-name "$KEYVAULT_NAME" --output none
    az keyvault secret set --name tf-sp-id --value "$APP_ID" --vault-name "$KEYVAULT_NAME" --output none
    az keyvault secret set --name tf-sp-secret --value "$SP_PASSWD" --vault-name "$KEYVAULT_NAME" --output none
    az keyvault secret set --name tf-tenant-id --value "$TENANT_ID" --vault-name "$KEYVAULT_NAME" --output none
    az keyvault secret set --name tf-storage-name --value "${TF_STATE_STORAGE_ACCOUNT_NAME}" --vault-name "$KEYVAULT_NAME" --output none

    # Display information
    echo -e "\n"
    echo "Run the following command to initialize Terraform to store its state into Azure Storage:"
    echo "terraform init -backend-config=\"storage_account_name=${TF_STATE_STORAGE_ACCOUNT_NAME}\" -backend-config=\"container_name=$TF_STATE_CONTAINER_NAME\" -backend-config=\"access_key=\$(az keyvault secret show --name tfstate-storage-key --vault-name $KEYVAULT_NAME --query value -o tsv)\" -backend-config=\"key=terraform.tfstate\""


    # Continue to create next env.
    echo -e "------------------------------------ \n"
    read -rp "Any other env to create? (y/n) " answer
    if ! [[ $answer =~ ^[Yy]$ ]]
    then
        break
    fi
done
