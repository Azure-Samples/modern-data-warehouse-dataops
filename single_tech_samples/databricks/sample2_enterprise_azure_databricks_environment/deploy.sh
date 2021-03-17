#!/usr/bin/env bash

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
    echo "Creating resource group $AZURE_RESOURCE_GROUP_NAME in $AZURE_RESOURCE_GROUP_LOCATION."
    az group create --location "$AZURE_RESOURCE_GROUP_LOCATION" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
else
    echo "Resource group $AZURE_RESOURCE_GROUP_NAME exists in $AZURE_RESOURCE_GROUP_LOCATION."
    RG_LOCATION=$(az group show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --query location)
    if [[ "$RG_LOCATION" != "\"$AZURE_RESOURCE_GROUP_LOCATION\"" ]]; then
        echo "Resource group $AZURE_RESOURCE_GROUP_NAME is located in $RG_LOCATION, not \"$AZURE_RESOURCE_GROUP_LOCATION\""
    fi
fi

# Validate the ARM templates (Jacob)

securityGroupName="${DEPLOYMENT_PREFIX}nsg01"
securityGroupLocation="$AZURE_RESOURCE_GROUP_LOCATION"

echo "Validating parameters for Network Security Group..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./securitygroup/securitygroup.template.json \
    --parameters \
        securityGroupName="$securityGroupName" \
        securityGroupLocation="$securityGroupLocation" \
    --output none; then
    echo "Validation error for Network Security Group, please see the error above."
    exit 1
else
    echo "Network Security Group parameters are valid."
fi

securityGroupName="${DEPLOYMENT_PREFIX}nsg01"
vnetName="${DEPLOYMENT_PREFIX}vnet01"
vnetLocation="$AZURE_RESOURCE_GROUP_LOCATION"

echo "Validating parameters for Virtual Network..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./vnet/vnet.template.json \
    --parameters \
        securityGroupName="$securityGroupName" \
        vnetName="$vnetName" \
        vnetLocation="$vnetLocation" \
    --output none; then
    echo "Validation error for Virtual Network, please see the error above."
    exit 1
else
    echo "Virtual Network parameters are valid."
fi

tagValues="{}"

securityGroupName="${DEPLOYMENT_PREFIX}nsg01"
vnetName="${DEPLOYMENT_PREFIX}vnet01"
disablePublicIp=false
adbWorkspaceLocation="$AZURE_RESOURCE_GROUP_LOCATION"
adbWorkspaceName="${DEPLOYMENT_PREFIX}adb01"
adbWorkspaceSkuTier="standard"

echo "Validating parameters for Azure Databricks..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./databricks/workspace.template.json \
    --parameters \
        vnetName="$vnetName" \
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

keyVaultName="${DEPLOYMENT_PREFIX}akv01"
keyVaultLocation="$AZURE_RESOURCE_GROUP_LOCATION"
enabledForDeployment="false"
enabledForTemplateDeployment="false"
tenantId="$(az account show --query "tenantId" --output tsv)"
objectId="$(az ad signed-in-user show --query "objectId" --output tsv)"
keyVaultSkuTier="Standard"

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

storageAccountName="${DEPLOYMENT_PREFIX}asa01"
storageAccountSku="Standard_LRS"
storageAccountSkuTier="Standard"
storageAccountLocation="$AZURE_RESOURCE_GROUP_LOCATION"
encryptionEnabled="true"

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

# Deploy ARM templates (Jacob)
echo "Deploying Network Security Group..."
nsg_arm_output=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./securitygroup/securitygroup.template.json \
    --parameters \
        securityGroupName="$securityGroupName" \
        securityGroupLocation="$securityGroupLocation" \
    --output json)

if [[ -z $nsg_arm_output ]]; then
    echo >&2 "Network Security Group ARM deployment failed."
    exit 1
fi

echo "Deploying Virtual Network..."
vnet_arm_output=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./vnet/vnet.template.json \
    --parameters \
        securityGroupName="$securityGroupName" \
        vnetName="$vnetName" \
        vnetLocation="$vnetLocation" \
    --output json)

if [[ -z $vnet_arm_output ]]; then
    echo >&2 "Virtual Network ARM deployment failed."
    exit 1
fi

echo "Deploying Azure Databricks Workspace..."
adbws_arm_output=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./databricks/workspace.template.json \
    --parameters \
        vnetName="$vnetName" \
        disablePublicIp="$disablePublicIp" \
        adbWorkspaceLocation="$adbWorkspaceLocation" \
        adbWorkspaceName="$adbWorkspaceName" \
        adbWorkspaceSkuTier="$adbWorkspaceSkuTier" \
        tagValues="$tagValues" \
    --output json)

if [[ -z $adbws_arm_output ]]; then
    echo >&2 "Databricks ARM deployment failed."
    exit 1
fi

echo "Deploying Azure Key Vault..."
akv_arm_output=$(az deployment group create \
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
if [[ -z $akv_arm_output ]]; then
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

# ###########################
# # RETRIEVE DATABRICKS INFORMATION AND GENERATE TOKEN
echo "Retrieving Databricks information from the deployment."
databricks_workspace_id=$(echo "$adbws_arm_output" | jq -r '.properties.outputs.databricks_workspace_id.value')
DATABRICKS_HOST=https://$(echo "$adbws_arm_output" | jq -r '.properties.outputs.databricks_workspace.value.workspaceUrl')
export DATABRICKS_HOST

# Retrieve databricks PAT token
echo "Generating a Databricks PAT token."
databricks_global_token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken) # Databricks app global id
azure_api_token=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)
api_response=$(curl -sf "$DATABRICKS_HOST"/api/2.0/token/create \
    -H "Authorization: Bearer $databricks_global_token" \
    -H "X-Databricks-Azure-SP-Management-Token:$azure_api_token" \
    -H "X-Databricks-Azure-Workspace-Resource-Id:$databricks_workspace_id" \
    -d '{ "comment": "For deployment" }')
databricks_token=$(echo "$api_response" | jq -r '.token_value')
export DATABRICKS_TOKEN=$databricks_token

echo "Waiting for Databricks workspace to be ready..."
# TODO: -> sleep 3m # if the cluster is going to get created after the token is in there ... need to add the sleep 3.
echo "DATABRICKS token generated"

# Store token in Key Vault (Juan)
echo "Storing DATABRICKS token secret in Key Vault."
az keyvault secret set -n "DatabricksDeploymentToken" --vault-name "$keyVaultName" --value "$DATABRICKS_TOKEN" --output none
echo "Successfully stored secret DatabricksDeploymentToken"

# Store Storage Account keys in Key Vault (Juan)
echo "Retrieving keys from storage account"
storage_keys=$(az storage account keys list --resource-group "$AZURE_RESOURCE_GROUP_NAME" --account-name "$storageAccountName")
storage_account_key1=$(echo "$storage_keys" | jq -r '.[0].value')
storage_account_key2=$(echo "$storage_keys" | jq -r '.[1].value')

echo "Storing keys in key vault"
az keyvault secret set -n "StorageAccountKey1" --vault-name "$keyVaultName" --value "$storage_account_key1" --output none
az keyvault secret set -n "StorageAccountKey2" --vault-name "$keyVaultName" --value "$storage_account_key2" --output none
echo "Successfully stored secrets StorageAccountKey1 and StorageAccountKey2"

##### Create ADB secret scope
# TODO: validate scope create with kv as backend issue https://github.com/DataThirstLtd/azure.databricks.cicd.tools/issues/43
# key_vault_id=$(echo $akv_arm_output | jq -r '.properties.outputs.keyvault_id.value')
# key_vault_uri=$(echo $akv_arm_output | jq -r '.properties.outputs.keyvault_uri.value')
# databricks secrets create-scope \
#     --scope deploymentsecretscope \
#     --scope-backend-type AZURE_KEYVAULT \
#     --initial-manage-principal users \
#     --resource-id $key_vault_id \
#     --dns-name $key_vault_uri
# TODO: use a sp to connect to SA instead of keys
# for now we will be creating the secret scope using the ADP token
scope_name="storage_scope"
if ! (databricks secrets list-scopes |  grep -q "$scope_name"); then
    echo "Creating secrets scope: $scope_name"
    # including --initial-manage-principal users as adb ws sku == Standard
    databricks secrets create-scope --scope "$scope_name" --initial-manage-principal "users"
fi

# Create secrets
echo "Creating secrets within scope $scope_name..."

databricks secrets write --scope "$scope_name" --key "storage_account_key1" --string-value  "$storage_account_key1"
databricks secrets write --scope "$scope_name" --key "storage_account_key2" --string-value  "$storage_account_key2"

###############################
# Summary or resources created:
printf "\n\n\nRESOURCE GROUP: \t\t %s\n" "$AZURE_RESOURCE_GROUP_NAME"
printf "STORAGE ACCOUNT: \t\t %s\n" "$storageAccountName"
printf "DATABRICKS WORKSPACE: \t\t %s\n" "$adbWorkspaceName"
printf "KEY VAULT NAME: \t\t %s\n" "$keyVaultName"
printf "NETWORK SECURITY GROUP: \t\t %s\n" "$securityGroupName"
printf "VIRTUAL NETWORK: \t\t %s\n" "$vnetName"
printf "\nSecret names:\n"
printf "DATABRICKS TOKEN: \t\t DatabricksDeploymentToken\n"
printf "STORAGE ACCOUNT KEY 1: \t\t StorageAccountKey1\n"
printf "STORAGE ACCOUNT KEY 2: \t\t StorageAccountKey2\n"
