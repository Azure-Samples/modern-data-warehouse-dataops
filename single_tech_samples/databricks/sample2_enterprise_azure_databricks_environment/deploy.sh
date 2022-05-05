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
    echo "Default location will be set to -> westus"
    AZURE_RESOURCE_GROUP_LOCATION="westus"
fi

# Variables for each resource
securityGroupName="${DEPLOYMENT_PREFIX}nsg01"
securityGroupLocation="$AZURE_RESOURCE_GROUP_LOCATION"

spokeVnetName="${DEPLOYMENT_PREFIX}spokeVnet01"
hubVnetName="${DEPLOYMENT_PREFIX}hubVnet01"
vnetLocation="$AZURE_RESOURCE_GROUP_LOCATION"

tagValues="{}"
disablePublicIp=true
adbWorkspaceLocation="$AZURE_RESOURCE_GROUP_LOCATION"
adbWorkspaceName="${DEPLOYMENT_PREFIX}adb01"
adbWorkspaceSkuTier="standard"

keyVaultName="${DEPLOYMENT_PREFIX}akv01"
keyVaultLocation="$AZURE_RESOURCE_GROUP_LOCATION"
enabledForDeployment="false"
enabledForTemplateDeployment="false"
tenantId="$(az account show --query "tenantId" --output tsv)"
objectId="$(az ad signed-in-user show --query "objectId" --output tsv)"
keyVaultSkuTier="Standard"

storageAccountName="${DEPLOYMENT_PREFIX}asa01"
storageAccountSku="Standard_LRS"
storageAccountSkuTier="Standard"
storageAccountLocation="$AZURE_RESOURCE_GROUP_LOCATION"
encryptionEnabled="true"

reouteTablelocation="$AZURE_RESOURCE_GROUP_LOCATION"
routeTableName="${DEPLOYMENT_PREFIX}FWRT01"

firewallName="${DEPLOYMENT_PREFIX}HubFW01"
iPAddressName="${DEPLOYMENT_PREFIX}FWIP01"
firewalllocation="$AZURE_RESOURCE_GROUP_LOCATION"
# default IPs and Domains for westus region
webappDestinationAddresses="[
    \"40.118.174.12/32\",
    \"20.42.129.160/32\"
]"
logBlobstorageDomains="[
    \"dblogprodwestus.blob.core.windows.net\"
]"
infrastructureDestinationAddresses="[
    \"13.91.84.96/28\"
]"
sccRelayDomains="[
    \"tunnel.westus.azuredatabricks.net\"
]"
metastoreDomains="[
    \"consolidated-westus-prod-metastore.mysql.database.azure.com\",
    \"consolidated-westus-prod-metastore-addl-1.mysql.database.azure.com\",
    \"consolidated-westus-prod-metastore-addl-2.mysql.database.azure.com\",
    \"consolidated-westus-prod-metastore-addl-3.mysql.database.azure.com\",
    \"consolidated-westus2c2-prod-metastore-addl-1.mysql.database.azure.com\"
]"
eventHubEndpointDomains="[
    \"prod-westus-observabilityEventHubs.servicebus.windows.net\",
    \"prod-westus2c2-observabilityeventhubs.servicebus.windows.net\"
]"
artifactBlobStoragePrimaryDomains="[
    \"dbartifactsprodwestus.blob.core.windows.net\",
    \"arprodwestusa1.blob.core.windows.net\",
    \"arprodwestusa2.blob.core.windows.net\",
    \"arprodwestusa3.blob.core.windows.net\",
    \"arprodwestusa4.blob.core.windows.net\",
    \"arprodwestusa5.blob.core.windows.net\",
    \"arprodwestusa6.blob.core.windows.net\",
    \"arprodwestusa7.blob.core.windows.net\",
    \"arprodwestusa8.blob.core.windows.net\",
    \"arprodwestusa9.blob.core.windows.net\",
    \"arprodwestusa10.blob.core.windows.net\",
    \"arprodwestusa11.blob.core.windows.net\",
    \"arprodwestusa12.blob.core.windows.net\",
    \"arprodwestusa13.blob.core.windows.net\",
    \"arprodwestusa14.blob.core.windows.net\",
    \"arprodwestusa15.blob.core.windows.net\"
]"
dbfsBlobStrageDomain="[
    \"dbstorage************.blob.core.windows.net\"
]"
scopeName="storage_scope"

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
    echo "Creating resource group $AZURE_RESOURCE_GROUP_NAME in $AZURE_RESOURCE_GROUP_LOCATION."
    az group create --location "$AZURE_RESOURCE_GROUP_LOCATION" --resource-group "$AZURE_RESOURCE_GROUP_NAME" --output none
else
    echo "Resource group $AZURE_RESOURCE_GROUP_NAME exists in $AZURE_RESOURCE_GROUP_LOCATION."
    RG_LOCATION=$(az group show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --query location --output tsv)
    if [[ "$RG_LOCATION" != "\"$AZURE_RESOURCE_GROUP_LOCATION\"" ]]; then
        echo "Resource group $AZURE_RESOURCE_GROUP_NAME is located in $RG_LOCATION, not \"$AZURE_RESOURCE_GROUP_LOCATION\""
    fi
fi

# Validate the ARM templates (Jacob)
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

echo "Validating parameters for the Route Table..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./routetable/routetable.template.json \
    --parameters \
        routeTableName="$routeTableName" \
        reouteTablelocation="$reouteTablelocation" \
    --output none; then
    echo "Validation error for Route Table, please see the error above."
    exit 1
else
    echo "Route Table parameters are valid."
fi

echo "Validating parameters for Virtual Networks..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./vnet/vnet.template.json \
    --parameters \
        securityGroupName="$securityGroupName" \
        spokeVnetName="$spokeVnetName" \
        hubVnetName="$hubVnetName" \
        vnetLocation="$vnetLocation" \
        routeTableName="$routeTableName" \
    --output none; then
    echo "Validation error for Virtual Networks, please see the error above."
    exit 1
else
    echo "Virtual Networks parameters are valid."
fi

echo "Validating parameters for Azure Databricks..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./databricks/workspace.template.json \
    --parameters \
        vnetName="$spokeVnetName" \
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

echo "Validating parameters for the Firewall..."
if ! az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./firewall/firewall.template.json \
    --parameters \
        firewallName="$firewallName" \
        publicIpAddressName="$iPAddressName" \
        firewalllocation="$firewalllocation" \
        vnetName="$hubVnetName" \
        webappDestinationAddresses="$webappDestinationAddresses" \
        logBlobstorageDomains="$logBlobstorageDomains" \
        infrastructureDestinationAddresses="$infrastructureDestinationAddresses" \
        sccRelayDomains="$sccRelayDomains" \
        metastoreDomains="$metastoreDomains" \
        eventHubEndpointDomains="$eventHubEndpointDomains" \
        artifactBlobStoragePrimaryDomains="$artifactBlobStoragePrimaryDomains" \
        dbfsBlobStrageDomain="$dbfsBlobStrageDomain" \
    --output none; then
    echo "Validation error for Firewall, please see the error above."
    exit 1
else
    echo "Firewall parameters are valid."
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

echo "Validating parameters for Azure Key Vault Privatelink..."
if
    ! az deployment group validate \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --template-file ./keyvault/privateendpoint.template.json \
        --parameters \
            keyvaultPrivateLinkResource="somelinkresource" \
            targetSubResource="vault" \
            keyvaultName="$keyVaultName" \
            vnetName="$spokeVnetName" \
            privateLinkSubnetId="somelinkresource" \
            privateLinkLocation="$AZURE_RESOURCE_GROUP_LOCATION" \
        --output none
then
    echo "Validation error for Azure Key Vault Privatelink, please see the error above."
    exit 1
else
    echo "Azure Key Vault Privatelink parameters are valid."
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

echo "Validating parameters for Azure Storage Account Privatelink..."
if
    ! az deployment group validate \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --template-file ./storageaccount/privateendpoint.template.json \
        --parameters \
            storageAccountPrivateLinkResource="vault" \
            storageAccountName="$storageAccountName" \
            targetSubResource="dfs" \
            vnetName="$spokeVnetName" \
            privateLinkSubnetId="somelinkresource" \
            privateLinkLocation="$AZURE_RESOURCE_GROUP_LOCATION" \
        --output none
then
    echo "Validation error for Azure Storage Account Privatelink, please see the error above."
    exit 1
else
    echo "Azure Storage Account Privatelink parameters are valid."
fi

echo "******Starting deployments... ********"
echo "Deploying Network Security Group..."
nsgArmOutput=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./securitygroup/securitygroup.template.json \
    --parameters \
        securityGroupName="$securityGroupName" \
        securityGroupLocation="$securityGroupLocation" \
    --output json)

if [[ -z $nsgArmOutput ]]; then
    echo >&2 "Network Security Group ARM deployment failed."
    exit 1
fi

echo "Deploying Route Table..."
artArmOutput=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./routetable/routetable.template.json \
    --parameters \
        routeTableName="$routeTableName" \
        reouteTablelocation="$reouteTablelocation" \
    --output json)

if [[ -z $artArmOutput ]]; then
    echo >&2 "Route Table ARM deployment failed."
    exit 1
fi

echo "Deploying Virtual Network..."
vnetArmOutput=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./vnet/vnet.template.json \
    --parameters \
        securityGroupName="$securityGroupName" \
        spokeVnetName="$spokeVnetName" \
        hubVnetName="$hubVnetName" \
        vnetLocation="$vnetLocation" \
        routeTableName="$routeTableName" \
    --output json)

if [[ -z $vnetArmOutput ]]; then
    echo >&2 "Virtual Network ARM deployment failed."
    exit 1
fi

echo "Deploying Azure Databricks Workspace..."
adbwsArmOutput=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./databricks/workspace.template.json \
    --parameters \
        vnetName="$spokeVnetName" \
        disablePublicIp="$disablePublicIp" \
        adbWorkspaceLocation="$adbWorkspaceLocation" \
        adbWorkspaceName="$adbWorkspaceName" \
        adbWorkspaceSkuTier="$adbWorkspaceSkuTier" \
        tagValues="$tagValues" \
        adbWorkspaceSkuTier=premium \
    --output json)

if [[ -z $adbwsArmOutput ]]; then
    echo >&2 "Databricks ARM deployment failed."
    exit 1
fi

dbfsBlobStrageAccountName=$(az databricks workspace show -n "$adbWorkspaceName" -g "$AZURE_RESOURCE_GROUP_NAME" --query "parameters.storageAccountName.value" --output tsv)
dbfsBlobStrageDomain="[
    \"$dbfsBlobStrageAccountName.blob.core.windows.net\"
]"

echo "Deploying Firewall..."
afwArmOutput=$(az deployment group create \
    --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
    --template-file ./firewall/firewall.template.json \
    --parameters \
        firewallName="$firewallName" \
        publicIpAddressName="$iPAddressName" \
        firewalllocation="$firewalllocation" \
        vnetName="$hubVnetName" \
        webappDestinationAddresses="$webappDestinationAddresses" \
        logBlobstorageDomains="$logBlobstorageDomains" \
        infrastructureDestinationAddresses="$infrastructureDestinationAddresses" \
        sccRelayDomains="$sccRelayDomains" \
        metastoreDomains="$metastoreDomains" \
        eventHubEndpointDomains="$eventHubEndpointDomains" \
        artifactBlobStoragePrimaryDomains="$artifactBlobStoragePrimaryDomains" \
        dbfsBlobStrageDomain="$dbfsBlobStrageDomain" \
    --output json)

if [[ -z $afwArmOutput ]]; then
    echo >&2 "Firewall ARM deployment failed."
    exit 1
fi

echo "Deploying Azure Storage Account..."
asaArmOutput=$(
        az deployment group create \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --template-file ./storageaccount/storageaccount.template.json \
        --parameters \
            storageAccountName="$storageAccountName" \
            storageAccountSku="$storageAccountSku" \
            storageAccountSkuTier="$storageAccountSkuTier" \
            storageAccountLocation="$storageAccountLocation" \
            encryptionEnabled="$encryptionEnabled" \
        --output json
)

if [[ -z $asaArmOutput ]]; then
    echo >&2 "Storage Account ARM deployment failed."
    exit 1
fi

echo "Deploying Storage Account Private Link..."
if
    ! az deployment group create \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --template-file ./storageaccount/privateendpoint.template.json \
        --parameters \
            storageAccountPrivateLinkResource="$(echo "$asaArmOutput" | jq -r '.properties.outputs.storageaccount_id.value')" \
            storageAccountName="$storageAccountName" \
            targetSubResource="dfs" \
            vnetName="$spokeVnetName" \
            privateLinkSubnetId="$(echo "$vnetArmOutput" | jq -r '.properties.outputs.privatelinksubnet_id.value')" \
            privateLinkLocation="$AZURE_RESOURCE_GROUP_LOCATION" \
        --output none
then
    echo "Deployment of Azure Storage Account failed, please see the error above."
    exit 1
else
    echo "Deployment of Azure Storage Account succeeded."
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

# Store Storage Account keys in Key Vault
echo "Adding local IP into ACL while storing SA secrets (before private link config) ...."
az keyvault network-rule add --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$keyVaultName" --ip-address "$(curl -s ifconfig.me)" --output none
echo "Retrieving keys from storage account"
storageKeys=$(az storage account keys list --resource-group "$AZURE_RESOURCE_GROUP_NAME" --account-name "$storageAccountName" --output json)
storageAccountKey1=$(echo "$storageKeys" | jq -r '.[0].value')
storageAccountKey2=$(echo "$storageKeys" | jq -r '.[1].value')

echo "Storing keys in key vault"
az keyvault secret set -n "StorageAccountKey1" --vault-name "$keyVaultName" --value "$storageAccountKey1" --output none
az keyvault secret set -n "StorageAccountKey2" --vault-name "$keyVaultName" --value "$storageAccountKey2" --output none
echo "Successfully stored secrets StorageAccountKey1 and StorageAccountKey2"
echo "Removing local IP into ACL while storing secrets ...."
az keyvault network-rule remove --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$keyVaultName" --ip-address "$(curl -s ifconfig.me)/32" --output none
echo "Removed"

echo "Deploying Keyvault Private Link..."
if
    ! az deployment group create \
        --resource-group "$AZURE_RESOURCE_GROUP_NAME" \
        --template-file ./keyvault/privateendpoint.template.json \
        --parameters \
            keyvaultPrivateLinkResource="$(echo "$akvArmOutput" | jq -r '.properties.outputs.keyvault_id.value')" \
            targetSubResource="vault" \
            keyvaultName="$keyVaultName" \
            vnetName="$spokeVnetName" \
            privateLinkSubnetId="$(echo "$vnetArmOutput" | jq -r '.properties.outputs.privatelinksubnet_id.value')" \
            privateLinkLocation="$AZURE_RESOURCE_GROUP_LOCATION" \
        --output none
then
    echo "Deployment of Keyvault Private Link failed, please see the error above."
    exit 1
else
    echo "Deployment of Keyvault Private Link succeeded."
fi

# Create ADB secret scope backed by Key Vault
adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
echo "Got adbGlobalToken=\"${adbGlobalToken:0:20}...${adbGlobalToken:(-20)}\""
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)
echo "Got azureApiToken=\"${azureApiToken:0:20}...${azureApiToken:(-20)}\""

keyVaultId=$(echo "$akvArmOutput" | jq -r '.properties.outputs.keyvault_id.value')
keyVaultUri=$(echo "$akvArmOutput" | jq -r '.properties.outputs.keyvault_uri.value')

adbId=$(az databricks workspace show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$adbWorkspaceName" --query id --output tsv)
adbWorkspaceUrl=$(az databricks workspace show --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$adbWorkspaceName" --query workspaceUrl --output tsv)

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
printf "NETWORK SECURITY GROUP: \t\t %s\n" "$securityGroupName"
printf "SPOKE VIRTUAL NETWORK: \t\t %s\n" "$spokeVnetName"
printf "HUB VIRTUAL NETWORK: \t\t %s\n" "$hubVnetName"
printf "FIREWALL: \t\t %s\n" "$firewallName"
printf "ROUTING TABLE: \t\t %s\n" "$routeTableName"
printf "\nSecret names:\n"
printf "DATABRICKS TOKEN: \t\t DatabricksDeploymentToken\n"
printf "STORAGE ACCOUNT KEY 1: \t\t StorageAccountKey1\n"
printf "STORAGE ACCOUNT KEY 2: \t\t StorageAccountKey2\n"
