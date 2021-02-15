<#
This script creates several Azure Container Instances that runs the IoT Simulator.
All resources, including the resource group, will be torn down automatically
after the simulators finish sending the load.
#>
param (
    [string]$Location = 'japaneast',
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [int]$DeviceCount = 1,
    [int]$ContainerCount = 1,
    [int]$MessageCount = 1000,
    [int]$Interval = 1000,
    [string]$FixPayload = '',
    [int]$FixPayloadSize = 0,
    [string]$Header = '',
    [Parameter(Mandatory=$true)][string]$EventHubConnectionString,
    [string]$Image = "iottelemetrysimulator/azureiot-telemetrysimulator:latest",
    [double]$Cpu = 1.0,
    [double]$Memory = 1.5
 )

<#
We want the load to generate:
- 50% of the load where deviceId >= 1,000. The system is not interested in this data so these should be filter it out.
- 40% "good" data where deviceId <1,000 AND temperature <100
- 10% "bad" data where deviceId <1,000 AND temperature >100
#>
$FilteredTemplate = '{ \"deviceId\": \"$.FilteredDeviceId\", \"temperature\": $.Temperature, \"time\": \"$.Time\" }'
$GoodTemplate = '{ \"deviceId\": \"$.DeviceId\", \"temperature\": $.Temperature, \"time\": \"$.Time\" }'
$BadTemplate = '{ \"deviceId\": \"$.DeviceId\", \"temperature\": $.BadTemperature, \"time\": \"$.Time\" }'
$Variables = '[{name: \"DeviceId\", random: true, max: 999, min: 0}, {name: \"FilteredDeviceId\", random: true, min: 1000}, {name: \"Temperature\", random: true, max: 99, min: 0}, {name: \"BadTemperature\", random: true, min: 100}]'

$i = 0
$deviceIndex = 1
$devicesPerContainer = [int]($DeviceCount / $ContainerCount)
while($i -lt $ContainerCount)
{
   $i++
   $containerName = "iotsimulator-" + $i.ToString()
   az container create -g $ResourceGroup --no-wait --location $Location --restart-policy Never `
   --cpu $Cpu --memory $Memory --name $containerName --image $Image `
   --environment-variables EventHubConnectionString=$EventHubConnectionString `
   GoodTemplate=$GoodTemplate BadTemplate=$BadTemplate FilteredTemplate=$FilteredTemplate Variables=$Variables `
   PayloadDistribution='template(50, FilteredTemplate) template(40, GoodTemplate) template(10, BadTemplate)' `
   DeviceCount=$devicesPerContainer MessageCount=$MessageCount DeviceIndex=$deviceIndex `
   Interval=$Interval Header=$Header FixPayloadSize=$FixPayloadSize FixPayload=$FixPayload

   $deviceIndex = $deviceIndex + $devicesPerContainer
}

Write-Host "Creation of" $ContainerCount "container instances has started. Telemetry will start flowing soon"

# Record load test start time for our LoadTestCheckResult.ps1.
$currentTime = Get-Date -Format "o"
Write-Host "##vso[task.setvariable variable=LoadTestStartTime]$currentTime"

<#
Start tracking each container instance's state.
Tear down the container instance if it finishes sending the load.
#>
Write-Host "Start checking the state of each container instances: "

for($i = 1; $i -le $ContainerCount; $i++)
{
   $containerName = "iotsimulator-" + $i.ToString()
   $containerTerminated = $false

   while(!$containerTerminated){
      $containerInfo = az container show --resource-group $ResourceGroup --name $containerName | ConvertFrom-Json
      $containerState = $containerInfo.containers[0].instanceView.currentState.state
      if($containerState -eq "Terminated") {
         Write-Host "   Container" $containerName "is terminated."
         $containerTerminated = $true
         az container delete --name $containerName --resource-group $ResourceGroup --yes
         Write-Host "   Container" $containerName "is deleted."
      }
      else {
         # Check the state again after 2 sec
         Start-Sleep -s 2
      }
   }
}

Write-Host "All resources are deleted."
