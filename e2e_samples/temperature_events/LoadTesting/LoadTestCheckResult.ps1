<#
This script fetches the Incoming Messages and Outgoing Messages Metrics for the eventhub
where the IoT Simulator sends the load to. If the total num of Incoming Messages <= Outgoing Messages, 
we let this automated load test pass. We suggest that you look into the metrics through portal manually 
again to confirm or gain more insights about whether the system is behaving as expected.
#>
param (
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter(Mandatory=$true)][string]$EvhNamespace,
    [Parameter(Mandatory=$true)][string]$EvhName,
    [string]$aggregationUnit = "24h"
 )

$EvhNamespaceResourceId="/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.EventHub/namespaces/$EvhNamespace"
$currentTime = Get-Date -Format "o"

Write-Host " az monitor metrics list `
--resource $EvhNamespaceResourceId `
--metrics 'IncomingMessages' `
--filter 'EntityName eq '$EvhName' ' `
--start-time $env:LOADTESTSTARTTIME `
--end-time $currentTime `
--interval $aggregationUnit "

# Get the total number of incoming messages.
$ingress_metric = az monitor metrics list `
--resource $EvhNamespaceResourceId `
--metrics "IncomingMessages" `
--filter "EntityName eq '$EvhName' " `
--start-time $env:LOADTESTSTARTTIME `
--end-time $currentTime `
--interval $aggregationUnit | ConvertFrom-Json

Write-Host "result: $ingress_metric"
Write-Host "ts: $ingress_metric.value[0].timeseries[0]"
Write-Host "data: $ingress_metric.value[0].timeseries[0].data[0]"

$ingress_num = $ingress_metric.value[0].timeseries[0].data[0].total

# Get the total number of outgoing messages.
$egress_metric = az monitor metrics list `
--resource $EvhNamespaceResourceId `
--metrics "OutgoingMessages" `
--filter "EntityName eq '$EvhName' " `
--start-time $env:LOADTESTSTARTTIME `
--end-time $currentTime `
--interval $aggregationUnit | ConvertFrom-Json

$egress_num = $egress_metric.value[0].timeseries[0].data[0].total

# Output
Write-Host "Incoming Messages during load test: $ingress_num messages"
Write-Host "Outgoing Messages during load test: $egress_num messages"

# If ingress > egress, test fails (just an example condition.)
if ($ingress_num -le $egress_num){
  Write-Host "Load test passed."
} else {
  throw "Load test failed."
}
