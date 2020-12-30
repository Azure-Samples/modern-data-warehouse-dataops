<#
This script creates several Azure Container Instances that runs the IoT Simulator.
All resources, including the resource group, will be torn down automatically 
after the simulators finish sending the load.
#>
param (
    [string]$Location = 'japaneast',
    [string]$ResourceGroup = 'iotsimulator',
    [int]$DeviceCount = 1,
    [int]$ContainerCount = 1,
    [int]$MessageCount = 1,
    [int]$Interval = 1000,
    [string]$FixPayload = '',
    [int]$FixPayloadSize = 0,
    [string]$Template = '{ \"deviceId\": \"$.DeviceId\", \"temp\": $.Temp, \"Ticks\": $.Ticks, \"Counter\": $.Counter, \"time\": \"$.Time\", \"engine\": \"$.Engine\", \"source\": \"$.MachineName\" }',
    [string]$Header = '',
    [string]$Variables = '[{name: \"Temp\", random: true, max: 25, min: 23}, {name:\"Counter\", min:100}, {name:\"Engine\", values: [\"on\", \"off\"]}]',
    [Parameter(Mandatory=$true)][string]$EventHubConnectionString,
    [string]$Image = "iottelemetrysimulator/azureiot-telemetrysimulator:latest",
    [double]$Cpu = 1.0,
    [double]$Memory = 1.5
 )

<#
We want the load to generate:
- 50% of the load where deviceId > 1,000. The system is not interested in this data so these should be filter it out.
- 40% "good" data where deviceId <1,000 AND temperature <100
- 10% "bad" data where deviceId <1,000 AND temperature >100
#>
$FilteredTemplate = '{ \"deviceId\": \"$.FilteredDeviceId\", \"temp\": $.Temp, \"time\": \"$.Time\" }' 
$GoodTemplate = '{ \"deviceId\": \"$.DeviceId\", \"temp\": $.Temp, \"time\": \"$.Time\" }'
$BadTemplate = '{ \"deviceId\": \"$.DeviceId\", \"temp\": $.BadTemp, \"time\": \"$.Time\" }' 
$Variables = '[{name: \"DeviceId\", random: true, max: 1000, min: 0}, {name: \"FilteredDeviceId\", random: true, min: 1000}, {name: \"Temp\", random: true, max: 100, min: 0}, {name: \"BadTemp\", random: true, min: 100}]'

az group create --name $ResourceGroup --location $Location

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
Tear down all resources after all container instances finish sending the load. 
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
      }
      else {
         # Check the state again after 2 sec
         Start-Sleep -s 2
      }
   }
}

Write-Host "Deleting" $ResourceGroup "resource group."

az group delete --name $ResourceGroup --yes

Write-Host "All resources are deleted."
