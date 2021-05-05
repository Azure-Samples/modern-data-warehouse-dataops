#!/usr/bin/env pwsh

# Create SPN to manage Purview

$scope = "/subscriptions/$env:SUBSCRIPTIONID/resourceGroups/$env:RESOURCE_GROUP/providers/Microsoft.Purview/accounts/$env:PURVIEWACCOUNTNAME"

# Alternative code where SPN is created on the fly; requires AD API permissions Directory.Read.All and Application.ReadWrite.OwnedBy
# $az_sp_name = "$env:PURVIEWACCOUNTNAME-purview-sp"
# $az_sp = (az ad sp create-for-rbac --role owner --scopes $scope --name $az_sp_name --output json)

# $PURVIEW_SPN_APP_ID = ($az_sp | ConvertFrom-Json).appId
# $PURVIEW_SPN_APP_KEY= ($az_sp | ConvertFrom-Json).password

$PURVIEW_SPN_APP_ID = $env:servicePrincipalId
$PURVIEW_SPN_APP_KEY = $env:servicePrincipalKey

az keyvault secret set --name "pureview-appId" --vault-name $env:KEYVAULTNAME --value $PURVIEW_SPN_APP_ID
az keyvault secret set --name "pureview-password" --vault-name $env:KEYVAULTNAME --value $PURVIEW_SPN_APP_KEY

$purviewadmins = $env:PURVIEWADMINS, $PURVIEW_SPN_APP_ID

$roles = "Owner", "Purview Data Source Administrator", "Purview Data Curator", "Purview Data Reader"

foreach ($purviewadmin in $purviewadmins) {
    foreach ($role in $roles) {
        az role assignment create --assignee $purviewadmin --role $role --scope $scope
    }
}
