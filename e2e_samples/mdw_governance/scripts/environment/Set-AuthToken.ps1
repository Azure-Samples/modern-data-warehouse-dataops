#!/usr/bin/env pwsh

# Get SPN keys from keyvault
$appId = (az keyvault secret show --name "pureview-appId" --vault-name $env:KEYVAULTNAME | ConvertFrom-Json).value
$password = [System.Web.HTTPUtility]::UrlEncode((az keyvault secret show --name "pureview-password" --vault-name $env:KEYVAULTNAME | ConvertFrom-Json).value)


# Get TenantId
$tenantId = (az account show | ConvertFrom-Json).tenantId

$loginURL = "https://login.microsoftonline.com/$tenantId/oauth2/token"

$loginBody = "grant_type=client_credentials
&client_id=$appId
&client_secret=$password
&resource=https%3A%2F%2Fpurview.azure.net"

# Get access token by logging in with SPN
$env:ACCESS_TOKEN = ((Invoke-WebRequest -Uri $loginURL -Method POST -Body $loginBody).Content | ConvertFrom-Json).access_token
