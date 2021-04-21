#!/usr/bin/env pwsh

# Connect a Data Lake to Purview for file scanning

# Login with SPN and set token to env variable
./scripts/environment/Set-AuthToken.ps1

# Set bearer token header
$headers = @{
    Authorization = "Bearer $env:ACCESS_TOKEN"
    }

$atlasAPI = "https://$env:PURVIEWACCOUNTNAME.scan.purview.azure.com"

# Create a new ADL source
$scanURL = "$atlasAPI/datasources/$env:STORAGE_ACCOUNT_NAME"+"?api-version=2018-12-01-preview"

$scanBody = @{
  properties = @{
    endpoint= "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net"
  }
  kind = "AdlsGen2"
}

$scanBodyJson = $scanBody | ConvertTo-Json

Invoke-WebRequest -Uri $scanURL -Method PUT -Body $scanBodyJson -Headers $headers -ContentType 'application/json'
