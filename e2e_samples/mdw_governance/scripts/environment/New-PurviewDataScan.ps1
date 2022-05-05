#!/usr/bin/env pwsh

# Login with SPN and set token to env variable
./scripts/environment/Set-AuthToken.ps1

# Set bearer token header
$headers = @{
    Authorization = "Bearer $env:ACCESS_TOKEN"
    }

$atlasAPI = "https://$env:PURVIEWACCOUNTNAME.scan.purview.azure.com"

# Create a new scan
$scanURL = "$atlasAPI/datasources/$env:STORAGE_ACCOUNT_NAME/scans/$env:STORAGE_ACCOUNT_NAME-Scan"

$scanBody = @{
  properties = @{
    scanRulesetName = "AdlsGen2"
    scanRulesetType = "System"
  }
  kind = "AdlsGen2Msi"
}

$scanBodyJson = $scanBody | ConvertTo-Json

Invoke-WebRequest -Uri $scanURL -Method PUT -Body $scanBodyJson -Headers $headers -ContentType 'application/json'

# Create a new filter on the scan
# Note: currently you have to explicitly include, and exclude folders, wildcards are not yet supported
$filterURL = "$scanURL/filters/custom"

$filterBody = @{
  properties = @{
    excludeUriPrefixes = @(
      "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net/$env:BASECONTAINER/Malformed",
      "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net/$env:BASECONTAINER/Sandbox"
    )
    includeUriPrefixes = @(
      "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net/",
      "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net/$env:BASECONTAINER",
      "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net/$env:BASECONTAINER/Bronze",
      "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net/$env:BASECONTAINER/Gold",
      "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net/$env:BASECONTAINER/Silver",
      "https://$env:STORAGE_ACCOUNT_NAME.dfs.core.windows.net/$env:BASECONTAINER/Sys"
    )
  }
}

$filterBodyJson = $filterBody | ConvertTo-Json

Invoke-WebRequest -Uri $filterURL -Method PUT -Body $filterBodyJson -Headers $headers -ContentType 'application/json'
