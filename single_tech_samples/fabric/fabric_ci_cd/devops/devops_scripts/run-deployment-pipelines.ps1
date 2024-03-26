# This sample script calls the Fabric API to programmatically update workspace content.
 
param
(
    [parameter(Mandatory = $false)] [String] $baseUrl,
    [parameter(Mandatory = $false)] [String] $fabricToken,
    [parameter(Mandatory = $false)] [String] $pipelineName,
    [parameter(Mandatory = $false)] [String] $sourceStageName,
    [parameter(Mandatory = $false)] [String] $targetStageName,
    [parameter(Mandatory = $false)] [String] $targetStageWsName
)
 
function GetErrorResponse($exception) {
    # Relevant only for PowerShell Core
    $errorResponse = $_.ErrorDetails.Message
 
    if(![string]::IsNullOrEmpty($errorResponse)) {
        # This is needed to support Windows PowerShell
        $result = $exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $errorResponse = $reader.ReadToEnd();
    }
    else {
        $errorResponse = $exception
    }
 
    return $errorResponse
}
 
try {
    $fabricHeaders = @{
        'Content-Type' = "application/json"
        'Authorization' = "Bearer {0}" -f $fabricToken
    }
 
    # Get pipelines & Try to find the pipeline by display name
    $deploymentPipelinesUrl = "{0}/deploymentPipelines" -f $baseUrl
    $pipelines = (Invoke-RestMethod -Headers $fabricHeaders -Uri $deploymentPipelinesUrl -Method GET).value
    $pipeline = $pipelines | Where-Object {$_.DisplayName -eq $pipelineName}
    Write-Host "PIPELINE ['$pipelineName']"
    if(!$pipeline) {
        Write-Host "A pipeline with the requested name ['$pipelineName'] was not found"
        return
    }

    # Get pipeline stages & Try to find the source and target stages by display name
    $stagesUrl = "{0}/deploymentPipelines/{1}/stages" -f $baseUrl, $pipeline.id
    $stages = (Invoke-RestMethod -Headers $fabricHeaders -Uri $stagesUrl -Method GET).value    
    $sourceStage = $stages | Where-Object {$_.DisplayName -eq $sourceStageName}    
    Write-Host "Source STG ['$sourceStage']"
    if(!$sourceStage) {
        Write-Host "Cannot find source stage '$sourceStageName'"
        return
    }
    
    $targetStage = $stages | Where-Object {$_.DisplayName -eq $targetStageName}
    Write-Host "Source STG ['$targetStage']"
    if(!$targetStage) {
        Write-Host "Cannot find target stage '$targetStageName'"
        return
    }

    Write-Host "Deploying '$pipelineName' from '$($sourceStage.displayName)' to '$($targetStage.displayName)'" -ForegroundColor Green

    # Construct the request url and body for deploy
    $deployUrl = "{0}/deploymentPipelines/{1}/deploy" -f $baseUrl, $pipeline.id

    $deployBody = @{
        note = "This is an aoutomated deploy!"
        sourceStageId = $sourceStage.id
        targetStageId = $targetStage.id
        createdWorkspaceDetails = @{ #Required when deploying to a stage that has no assigned workspace
            Name = $targetStageWsName
        } 
        #items - A list of items to be deployed. If not used, all stage items are deployed.
    } | ConvertTo-Json

    # Deploy pipeline
    Write-Host "Call '$deployUrl'" -ForegroundColor Green
    $deployResponse = Invoke-WebRequest -Headers $fabricHeaders -Uri $deployUrl -Method POST -Body $deployBody

    $operationId = $deployResponse.Headers['x-ms-operation-id']
    $retryAfter = $deployResponse.Headers['Retry-After']

    Write-Host "Long Running Operation ID: '$operationId' has been scheduled for deploying '$pipelineName', with a retry-after time of '$retryAfter' seconds." -ForegroundColor Green

    # Poll Long Running Operation
    $getOperationState = "{0}/operations/{1}" -f $baseUrl, $($operationId)
    Write-Host "Long operation EP '$getOperationState' ."
    do
    {
        $operationState = Invoke-RestMethod -Headers $fabricHeaders -Uri $getOperationState -Method GET
        Write-Host "Deploy '$pipelineName' operation status: $($operationState.Status)"
        if ($operationState.Status -in @("NotStarted", "Running")) {
            Start-Sleep -Seconds $($retryAfter)
        }
    } while($operationState.Status -in @("NotStarted", "Running"))
    if ($operationState.Status -eq "Failed") {
        Write-Host "Failed to deploy '$pipelineName'. Error reponse: $($operationState.Error | ConvertTo-Json)" -ForegroundColor Red
    }
    else{
        Write-Host "The pipeline '$pipelineName' has been successfully deployed from '$sourceStageName' to '$targetStageName'." -ForegroundColor Green
    }

} catch {
    $errorResponse = GetErrorResponse($_.Exception)
    Write-Host "Failed to deploy '$pipelineName'. Error reponse: $errorResponse" -ForegroundColor Red
    exit 1
}