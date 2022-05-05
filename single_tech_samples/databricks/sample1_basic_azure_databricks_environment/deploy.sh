#!/usr/bin/env bash

set -e

DEPLOYMENT_PREFIX=${DEPLOYMENT_PREFIX:-}
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
AZURE_RESOURCE_GROUP_NAME=${AZURE_RESOURCE_GROUP_NAME:-}
AZURE_RESOURCE_GROUP_LOCATION=${AZURE_RESOURCE_GROUP_LOCATION:-}

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

# Variables

tagValues="{}"

disablePublicIp=false
adbWorkspaceLocation="$AZURE_RESOURCE_GROUP_LOCATION"
adbWorkspaceName="${DEPLOYMENT_PREFIX}adb01"
adbWorkspaceSkuTier="premium"

keyVaultName="${DEPLOYMENT_PREFIX}akv01"
keyVaultLocation="$AZURE_RESOURCE_GROUP_LOCATION"
enabledForDeployment="false"
enabledForTemplateDeployment="false"
keyVaultSkuTier="Standard"

storageAccountName="${DEPLOYMENT_PREFIX}asa01"
storageAccountSku="Standard_LRS"
storageAccountSkuTier="Standard"
storageAccountLocation="$AZURE_RESOURCE_GROUP_LOCATION"
encryptionEnabled="true"

scopeName="storage_scope"

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
RG_EXISTS=$(az group exists --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output json)
RG_EXISTS=${RG_EXISTS//$'\r'/}
if [[ $RG_EXISTS == "false" ]]; then
    echo "Creating resource group $AZURE_RESOURCE_GROUP_NAME in $AZURE_RESOURCE_GROUP_LOCATION."
    az group create --location "$AZURE_RESOURCE_GROUP_LOCATION" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
else
    echo "Resource group $AZURE_RESOURCE_GROUP_NAME exists in $AZURE_RESOURCE_GROUP_LOCATION."
    RG_LOCATION=$(az group show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --query location --output tsv)
    if [[ "$RG_LOCATION" != "\"$AZURE_RESOURCE_GROUP_LOCATION\"" ]]; then
        echo "Resource group $AZURE_RESOURCE_GROUP_NAME is located in $RG_LOCATION, not \"$AZURE_RESOURCE_GROUP_LOCATION\""
    fi
fi

# Validate the ARM templates
echo "Validating parameters for Azure Databricks..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./databricks/workspace.template.json \
    --parameters \
        disablePublicIp="$disablePublicIp" \
        adbWorkspaceLocation="$adbWorkspaceLocation" \
        adbWorkspaceName="$adbWorkspaceName" \
        adbWorkspaceSkuTier="$adbWorkspaceSkuTier" \
        tagValues="$tagValues" \
    --output none; then
    echo "Validation error for Azure Databricks, please see the error above."
    exit 1
else
    echo "Azure Databricks parameters are valid."
fi

tenantId="$(az account show --query "tenantId" --output tsv)"

userType="$(az account show --query "user.type" --output tsv)"
userType=${userType//$'\r'/}
if [[ $userType == "servicePrincipal" ]]; then
    clientId="$(az account show --query "user.name" --output tsv)"
    clientId=${clientId//$'\r'/}
    objectId="$(az ad sp show --id "$clientId" --query objectId --output tsv)"
else
    objectId="$(az ad signed-in-user show --query "objectId" --output tsv)"
fi

echo "Validating parameters for Azure Key Vault..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./keyvault/keyvault.template.json \
    --parameters \
        keyVaultName="$keyVaultName" \
        keyVaultLocation="$keyVaultLocation" \
        enabledForDeployment="$enabledForDeployment" \
        enabledForTemplateDeployment="$enabledForTemplateDeployment" \
        tenantId="$tenantId" \
        objectId="$objectId" \
        keyVaultSkuTier="$keyVaultSkuTier" \
        tagValues="$tagValues" \
    --output none; then
    echo "Validation error for Azure Key Vault, please see the error above."
    exit 1
else
    echo "Azure Key Vault parameters are valid."
fi

echo "Validating parameters for Azure Storage Account..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./storageaccount/storageaccount.template.json \
    --parameters \
        storageAccountName="$storageAccountName" \
        storageAccountSku="$storageAccountSku" \
        storageAccountSkuTier="$storageAccountSkuTier" \
        storageAccountLocation="$storageAccountLocation" \
        encryptionEnabled="$encryptionEnabled" \
    --output none; then
    echo "Validation error for Azure Storage Account, please see the error above."
    exit 1
else
    echo "Azure Storage Account parameters are valid."
fi

# Deploy ARM templates
echo "Deploying Azure Databricks Workspace..."
adbwsArmOutput=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./databricks/workspace.template.json \
    --parameters \
        disablePublicIp="$disablePublicIp" \
        adbWorkspaceLocation="$adbWorkspaceLocation" \
        adbWorkspaceName="$adbWorkspaceName" \
        adbWorkspaceSkuTier="$adbWorkspaceSkuTier" \
        tagValues="$tagValues" \
    --output json)

if [[ -z $adbwsArmOutput ]]; then
    echo >&2 "Databricks ARM deployment failed."
    exit 1
fi

echo "Deploying Azure Key Vault..."
akvArmOutput=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./keyvault/keyvault.template.json \
    --parameters \
        keyVaultName="$keyVaultName" \
        keyVaultLocation="$keyVaultLocation" \
        enabledForDeployment="$enabledForDeployment" \
        enabledForTemplateDeployment="$enabledForTemplateDeployment" \
        tenantId="$tenantId" \
        objectId="$objectId" \
        keyVaultSkuTier="$keyVaultSkuTier" \
        tagValues="$tagValues" \
    --output json)
if [[ -z $akvArmOutput ]]; then
    echo >&2 "Key Vault ARM deployment failed."
    exit 1
fi

echo "Deploying Azure Storage Account..."
if ! az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./storageaccount/storageaccount.template.json \
    --parameters \
        storageAccountName="$storageAccountName" \
        storageAccountSku="$storageAccountSku" \
        storageAccountSkuTier="$storageAccountSkuTier" \
        storageAccountLocation="$storageAccountLocation" \
        encryptionEnabled="$encryptionEnabled" \
    --output none; then
    echo "Deployment of Azure Storage Account failed, please see the error above."
    exit 1
else
    echo "Deployment of Azure Storage Account succeeded."
fi

# Store Storage Account keys in Key Vault
echo "Retrieving keys from storage account"
storageKeys=$(az storage account keys list --resource-group "$AZURE_RESOURCE_GROUP_NAME" --account-name "$storageAccountName" --output json)
storageAccountKey1=$(echo "$storageKeys" | jq -r '.[0].value')
storageAccountKey2=$(echo "$storageKeys" | jq -r '.[1].value')

echo "Storing keys in key vault"
az keyvault secret set -n "StorageAccountKey1" --vault-name "$keyVaultName" --value "$storageAccountKey1" --output none
az keyvault secret set -n "StorageAccountKey2" --vault-name "$keyVaultName" --value "$storageAccountKey2" --output none
echo "Successfully stored secrets StorageAccountKey1 and StorageAccountKey2"

# Create ADB secret scope backed by Key Vault
adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
echo "Got adbGlobalToken=\"${adbGlobalToken:0:20}...${adbGlobalToken:(-20)}\""
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)
echo "Got azureApiToken=\"${azureApiToken:0:20}...${azureApiToken:(-20)}\""

keyVaultId=$(echo "$akvArmOutput" | jq -r '.properties.outputs.keyvault_id.value')
keyVaultUri=$(echo "$akvArmOutput" | jq -r '.properties.outputs.keyvault_uri.value')

az config set extension.use_dynamic_install=yes_without_prompt

adbId=$(az databricks workspace show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$adbWorkspaceName" --query id --output tsv)
adbWorkspaceUrl=$(az databricks workspace show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$adbWorkspaceName" --query workspaceUrl --output tsv)

echo "Storing Databricks Host and Token in key vault"
az keyvault secret set -n "DatabricksHost" --vault-name "$keyVaultName" --value "https://$adbWorkspaceUrl" --output none
az keyvault secret set -n "DatabricksToken" --vault-name "$keyVaultName" --value "$adbGlobalToken" --output none
echo "Successfully stored secrets DatabricksHost and DatabricksToken"

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$adbId"

createSecretScopePayload="{
  \"scope\": \"$scopeName\",
  \"scope_backend_type\": \"AZURE_KEYVAULT\",
  \"backend_azure_keyvault\":
  {
    \"resource_id\": \"$keyVaultId\",
    \"dns_name\": \"$keyVaultUri\"
  },
  \"initial_manage_principal\": \"users\"
}"
echo "$createSecretScopePayload" | curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
    --data-binary "@-" "https://${adbWorkspaceUrl}/api/2.0/secrets/scopes/create"

# Summary or resources created:
printf "\n\n\nRESOURCE GROUP: \t\t %s\n" "$AZURE_RESOURCE_GROUP_NAME"
printf "STORAGE ACCOUNT: \t\t %s\n" "$storageAccountName"
printf "DATABRICKS WORKSPACE: \t\t %s\n" "$adbWorkspaceName"
printf "KEY VAULT NAME: \t\t %s\n" "$keyVaultName"
printf "\nSecret names:\n"
printf "STORAGE ACCOUNT KEY 1: \t\t StorageAccountKey1\n"
printf "STORAGE ACCOUNT KEY 2: \t\t StorageAccountKey2\n"
printf "DATABRICKS HOST: \t\t DatabricksHost\n"
printf "DATABRICKS TOKEN: \t\t DatabricksToken\n"
