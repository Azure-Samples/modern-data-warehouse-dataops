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
    exit 1
fi

# Login to Azure and select the subscription
if ! AZURE_USERNAME=$(az account show --query user.name); then
    echo "No Azure account logged in, now trying to log in."
    az login --output none
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
else
    echo "Logged in as $AZURE_USERNAME, set the active subscription to \"$AZURE_SUBSCRIPTION_ID\""
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
fi

# Check the resource group and region
RG_EXISTS=$(az group exists --resource-group "$AZURE_RESOURCE_GROUP_NAME")
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
iPAddressName="${DEPLOYMENT_PREFIX}FWIP01"

echo "Delete Resouce Group? $DELETE_RESOURCE_GROUP"

if [[ $DELETE_RESOURCE_GROUP == true ]]; then
    echo "Deleting resource group: $AZURE_RESOURCE_GROUP_NAME with all the resources. In 5 seconds..."
    sleep 5s
    az group delete --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none --yes
    echo "Purging key vault..."
    az keyvault purge --subscription "$AZURE_SUBSCRIPTION_ID" -n "$keyVaultName" --output none
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
    echo "Public IP Address: $iPAddressName"

    echo "Deleting ADB workspace..."
    if ! az databricks workspace delete \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --name "$adbWorkspaceName" \
        --yes  \
        --debug 2>&1 >/dev/null | grep "Response status: 200"; then
        echo "Deleting of ADB workspace failed."
        exit 1
    else
        echo "Successfully deleted ADB workspace."
    fi

    echo "Deleting Key Vault..."
    if ! az keyvault delete \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --name "$keyVaultName" \
        --debug 2>&1 >/dev/null | grep "Response status: 200" \
    ||
       ! az keyvault purge \
        --subscription "$AZURE_SUBSCRIPTION_ID" \
        --name "$keyVaultName" \
        --output none; then
        echo "Deleting of Key Vault failed."
        exit 1
    else
        echo "Successfully deleted and purged Key Vault"
    fi

    echo "Deleting Storage Account..."
    if ! az storage account delete \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --name "$storageAccountName" \
        --yes \
        --debug 2>&1 >/dev/null | grep "Response status: 200"; then
        echo "Deleting of Azure Storage Account failed."
        exit 1
    else 
        echo "Successfully deleted Storage Account."
    fi

    echo "Deleting Firewall..."
    az network firewall delete --name "$firewallName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    echo "Successfully deleted Firewall"

    echo "Deleting Public-IP..."
    if ! az network public-ip delete \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --name "$iPAddressName" \
        --debug 2>&1 >/dev/null | grep "Response status: 200"; then
        echo "Deleting of Public-IP failed."
        exit 1
    else
        echo "Successfully deleted Public-IP"
    fi

    echo "Deleting Spoke Virtual Network..."
    if ! az network vnet delete \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --name "$spokeVnetName" \
        --debug 2>&1 >/dev/null | grep "Response status: 200"; then
        echo "Deleting of Spoke Virtual Network failed."
        exit 1
    else
        echo "Successfully deleted Spoke Virtual Network"
    fi

    echo "Deleting Hub Virtual Network..."
    if ! az network vnet delete \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --name "$hubVnetName" \
        --debug 2>&1 >/dev/null | grep "Response status: 200"; then
        echo "Deleting of Hub Virtual Network failed."
        exit 1
    else
        echo "Successfully deleted Hub Virtual Network"
    fi

    echo "Deleting Network Security Group..."
    if ! az network nsg delete \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --name "$securityGroupName" \
        --debug 2>&1 >/dev/null | grep "Response status: 200"; then
        echo "Deleting of Network Security Group failed."
        exit 1
    else
        echo "Successfully deleted Network Security Group."
    fi

    echo "Deleting Route table..."
    if ! az network route-table delete \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --name "$routeTableName" \
        --debug 2>&1 >/dev/null | grep "Response status: 200"; then
        echo "Deleting of Route table failed."
        exit 1
    else
        echo "Successfully deleted Route table"
    fi
fi
