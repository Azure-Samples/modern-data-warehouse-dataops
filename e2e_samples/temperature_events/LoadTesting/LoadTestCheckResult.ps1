<#
This script fetches the Incoming Messages and Outgoing Messages Metrics for the eventhub
where the IoT Simulator sends the load to. If the total num of Incoming Messages <= Outgoing Messages, 
we let this automated load test pass. We suggest that you look into the metrics through portal manually 
again to confirm or gain more insights about whether the system is behaving as expected.
#>
param (
    [Parameter(Mandatory=$true)][string]$evhSubscriptionId,
    [Parameter(Mandatory=$true)][string]$evhResourceGroup,
    [Parameter(Mandatory=$true)][string]$evhNamespace,
    [Parameter(Mandatory=$true)][string]$evhName
 )

$evhNamespaceResourceId="/subscriptions/$evhSubscriptionId/resourceGroups/$evhResourceGroup/providers/Microsoft.EventHub/namespaces/$evhNamespace"
$currentTime = Get-Date -Format "o"

# Get the total number of incoming messages.
$ingress_metric = az monitor metrics list `
--resource $evhNamespaceResourceId `
--metrics "IncomingMessages" `
--filter "EntityName eq '$evhName' " `
--start-time $env:LOADTESTSTARTTIME `
--end-time $currentTime `
--interval 24h | ConvertFrom-Json

$ingress_num = $ingress_metric.value[0].timeseries[0].data[0].total

# Get the total number of outgoing messages.
$egress_metric = az monitor metrics list `
--resource $evhNamespaceResourceId `
--metrics "OutgoingMessages" `
--filter "EntityName eq '$evhName' " `
--start-time $env:LOADTESTSTARTTIME `
--end-time $currentTime `
--interval 24h | ConvertFrom-Json

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
