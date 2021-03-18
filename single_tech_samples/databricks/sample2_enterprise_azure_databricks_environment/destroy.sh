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
    az databricks workspace delete --name "$adbWorkspaceName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --yes --output none
    echo "Successfully deleted ADB workspace"

    echo "Deleting Key Vault..."
    az keyvault delete --name "$keyVaultName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    az keyvault purge --subscription "$AZURE_SUBSCRIPTION_ID" -n "$keyVaultName" --output none
    echo "Successfully deleted and purged Key Vault"

    echo "Deleting Storage Account..."
    az storage account delete --name "$storageAccountName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --yes --output none
    echo "Successfully deleted Storage Account"

    echo "Deleting Firewall..."
    az network firewall delete --name "$firewallName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    echo "Successfully deleted Firewall"

    echo "Deleting Public-IP..."
    az network public-ip delete --name "$iPAddressName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    echo "Successfully deleted Public-IP"

    echo "Deleting Spoke Virtual Network..."
    az network vnet delete --name "$spokeVnetName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    echo "Successfully deleted Virtual Network"

    echo "Deleting Hub Virtual Network..."
    az network vnet delete --name "$hubVnetName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    echo "Successfully deleted Virtual Network"

    echo "Deleting Network Security Group..."
    az network nsg delete --name "$securityGroupName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    echo "Successfully deleted Network Security Group"

    echo "Deleting Public-IP..."
    az network public-ip delete --name "$iPAddressName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    echo "Successfully deleted Public-IP"

    echo "Deleting Route table..."
    az network route-table delete --name "$routeTableName" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
    echo "Successfully deleted Route table"
fi
