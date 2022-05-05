#!/usr/bin/env bash

DEPLOYMENT_PREFIX=${DEPLOYMENT_PREFIX:-}
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
AZURE_RESOURCE_GROUP_NAME=${AZURE_RESOURCE_GROUP_NAME:-}
AZURE_RESOURCE_GROUP_LOCATION=${AZURE_RESOURCE_GROUP_LOCATION:-}
DELETE_RESOURCE_GROUP=${DELETE_RESOURCE_GROUP:-}

if [[ -z "$DEPLOYMENT_PREFIX" ]]; then
    echo "No deployment prefix [DEPLOYMENT_PREFIX] specified."
    exit 1
fi
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified."
    exit 1
fi
if [[ -z "$AZURE_RESOURCE_GROUP_NAME" ]]; then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_NAME] specified."
    exit 1
fi
if [[ -z "$AZURE_RESOURCE_GROUP_LOCATION" ]]; then
    echo "No Azure resource group [AZURE_RESOURCE_GROUP_LOCATION] specified."
    echo "Default location will be set to -> westus"
    AZURE_RESOURCE_GROUP_LOCATION="westus"
fi

# Login to Azure and select the subscription
if ! AZURE_USERNAME=$(az account show --query user.name --output tsv); then
    echo "No Azure account logged in, now trying to log in."
    az login --output none
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
else
    echo "Logged in as $AZURE_USERNAME, set the active subscription to \"$AZURE_SUBSCRIPTION_ID\""
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
fi

# Check the resource group and region
RG_EXISTS=$(az group exists --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output tsv)
if [[ $RG_EXISTS == "false" ]]; then
    echo "Error: Resource group $AZURE_RESOURCE_GROUP_NAME in $AZURE_RESOURCE_GROUP_LOCATION does not exist."
else
    echo "Resource group $AZURE_RESOURCE_GROUP_NAME exists in $AZURE_RESOURCE_GROUP_LOCATION. Removing created resources"
fi

# Name references
adbWorkspaceName="${DEPLOYMENT_PREFIX}adb01"
keyVaultName="${DEPLOYMENT_PREFIX}akv01"
storageAccountName="${DEPLOYMENT_PREFIX}asa01"
spokeVnetName="${DEPLOYMENT_PREFIX}spokeVnet01"
hubVnetName="${DEPLOYMENT_PREFIX}hubVnet01"
securityGroupName="${DEPLOYMENT_PREFIX}nsg01"
routeTableName="${DEPLOYMENT_PREFIX}FWRT01"
firewallName="${DEPLOYMENT_PREFIX}HubFW01"
ipAddressName="${DEPLOYMENT_PREFIX}FWIP01"
keyVaultPrivateEndpoint="${DEPLOYMENT_PREFIX}akv01privateendpoint"
storageAccountPrivateEndpoint="${DEPLOYMENT_PREFIX}asa01privateendpoint"

echo "Delete Resouce Group? $DELETE_RESOURCE_GROUP"

if [[ $DELETE_RESOURCE_GROUP == true ]]; then
    echo "Deleting resource group: $AZURE_RESOURCE_GROUP_NAME with all the resources. In 5 seconds..."
    sleep 5s
    az group delete --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none --yes
    echo "Purging key vault..."
    az keyvault purge --subscription "$AZURE_SUBSCRIPTION_ID" --name "$keyVaultName" --output none
else
    echo "The following resources will be deleted:"
    echo "ADB Workspace: $adbWorkspaceName"
    echo "Key Vault: $keyVaultName"
    echo "Storage Account: $storageAccountName"
    echo "Spoke Virtual Network: $spokeVnetName"
    echo "Hub Virtual Network: $hubVnetName"
    echo "Network Security Group: $securityGroupName"
    echo "Routing Table: $routeTableName"
    echo "Firewall: $firewallName"
    echo "Public IP Address: $ipAddressName"

    echo "Validating ADB workspace..."
    if az databricks workspace show \
        --name "$adbWorkspaceName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting ADB workspace..."
        { az databricks workspace delete \
            --name "$adbWorkspaceName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
            --yes &&
            echo "Successfully deleted ADB workspace."; } ||
            {
                echo "Failed to delete ADB workspace."
                exit 1
            }
    else
        echo "$adbWorkspaceName was not found."
    fi

    echo "Validating Key Vault..."
    if az keyvault show \
        --name "$keyVaultName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Key Vault..."
        { az keyvault delete \
            --name "$keyVaultName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
            az keyvault purge \
                --subscription "$AZURE_SUBSCRIPTION_ID" \
                --name "$keyVaultName" &&
            echo "Successfully deleted and purged Key Vault."; } ||
            {
                echo "Failed to delete and purge Key Vault."
                exit 1
            }
    else
        echo "$keyVaultName was not found."
    fi

    echo "Validating Storage Account..."
    if az storage account show \
        --name "$storageAccountName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Storage Account..."
        { az storage account delete \
            --name "$storageAccountName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
            --yes &&
            echo "Successfully deleted Storage Account."; } ||
            {
                echo "Failed to delete Storage Account."
                exit 1
            }
    else
        echo "$storageAccountName was not found."
    fi

    echo "Validating Private Endpoint for Key Vault"
    if az network private-endpoint show \
        --name "$keyVaultPrivateEndpoint" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Private Endpoint for Key Vault"
        {
            az network private-endpoint delete \
                --name "$keyVaultPrivateEndpoint" \
                --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
                echo "Successfully deleted Private Endpoint for Key Vault."
        } ||
            {
                echo "Failed to delete Private Endpoint for Key Vault."
                exit 1
            }
    else
        echo "$keyVaultPrivateEndpoint was not found."
    fi

    echo "Validating Private Endpoint for Key Vault"
    if az network private-endpoint show \
        --name "$storageAccountPrivateEndpoint" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Private Endpoint for Key Vault"
        {
            az network private-endpoint delete \
                --name "$storageAccountPrivateEndpoint" \
                --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
                echo "Successfully deleted Private Endpoint for Key Vault."
        } ||
            {
                echo "Failed to delete Private Endpoint for Key Vault."
                exit 1
            }
    else
        echo "$storageAccountPrivateEndpoint was not found."
    fi

    echo "Validating Firewall..."
    if az network firewall show \
        --name "$firewallName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Firewall..."
        { az network firewall delete \
            --name "$firewallName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
            echo "Successfully deleted Firewall."; } ||
            {
                echo "Failed to delete Firewall."
                exit 1
            }
    else
        echo "$firewallName was not found."
    fi

    echo "Validating Public-IP..."
    if az network public-ip show \
        --name "$ipAddressName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Public-IP..."
        { az network public-ip delete \
            --name "$ipAddressName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
            echo "Successfully deleted Public-IP."; } ||
            {
                echo "Failed to delete Public-IP."
                exit 1
            }
    else
        echo "$ipAddressName was not found."
    fi

    echo "Validating Spoke Virtual Network..."
    if az network vnet show \
        --name "$spokeVnetName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Spoke Virtual Network..."
        { az network vnet delete \
            --name "$spokeVnetName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
            echo "Successfully deleted Spoke Virtual Network."; } ||
            {
                echo "Failed to delete Spoke Virtual Network."
                exit 1
            }
    else
        echo "$spokeVnetName was not found."
    fi

    echo "Validating Hub Virtual Network..."
    if az network vnet show \
        --name "$hubVnetName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Hub Virtual Network..."
        { az network vnet delete \
            --name "$hubVnetName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
            echo "Successfully deleted Hub Virtual Network."; } ||
            {
                echo "Failed to delete Hub Virtual Network."
                exit 1
            }
    else
        echo "$hubVnetName was not found."
    fi

    echo "Validating Network Security Group..."
    if az network nsg show \
        --name "$securityGroupName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Network Security Group..."
        { az network nsg delete \
            --name "$securityGroupName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
            echo "Successfully deleted Network Security Group."; } ||
            {
                echo "Failed to delete Network Security Group."
                exit 1
            }
    else
        echo "$securityGroupName was not found."
    fi

    echo "Validating Route table..."
    if az network route-table show \
        --name "$routeTableName" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Route table..."
        { az network route-table delete \
            --name "$routeTableName" \
            --resource-group "$AZURE_RESOURCE_GROUP_NAME" &&
            echo "Successfully deleted Route table."; } ||
            {
                echo "Failed to delete Route table."
                exit 1
            }
    else
        echo "$routeTableName was not found."
    fi

    echo "Validating Private DNS Zone for Key Vault..."
    if az network private-dns zone show \
        --name "privatelink.vaultcore.azure.net" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Private DNS Zone for Key Vault..."
        counter=0
        while :; do
            az network private-dns zone delete \
                --name "privatelink.vaultcore.azure.net" \
                --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
                --yes \
                --output none &&
                echo "Successfully deleted Private DNS Zone for Key Vault" && break ||
                echo "Delete failed retrying ..."  && ((counter++)) && sleep 10
            if [[ "$counter" == '3' ]]; then
                echo "Failed to delete Private DNS Zone for Key Vault"
                exit 1
            fi
        done
    else
        echo "privatelink.vaultcore.azure.net was not found."
    fi

    echo "Validating Private DNS Zone for Storage Account..."
    if az network private-dns zone show \
        --name "privatelink.dfs.core.windows.net" \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --output none; then
        echo "Deleting Private DNS Zone for Storage Account..."
        counter=0
        while :; do
            az network private-dns zone delete \
                --name "privatelink.dfs.core.windows.net" \
                --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
                --yes \
                --output none &&
                echo "Successfully deleted Private DNS Zone for Storage Account" && break ||
                echo "Delete failed retrying ..."  && ((counter++)) && sleep 10
            if [[ "$counter" == '3' ]]; then
                echo "Failed to delete Private DNS Zone for Storage Account"
                exit 1
            fi
        done
    else
        echo "privatelink.dfs.core.windows.net was not found."
    fi

fi
