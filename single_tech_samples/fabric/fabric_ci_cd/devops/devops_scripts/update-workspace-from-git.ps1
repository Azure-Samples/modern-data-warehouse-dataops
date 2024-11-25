# This sample script demonstrates how to update a Fabric workspace from Git using the Fabric GIT REST APIs.
param
(
    [parameter(Mandatory = $false)] [String] $baseUrl,
    [parameter(Mandatory = $false)] [String] $fabricToken,
    [parameter(Mandatory = $false)] [String] $workspaceName
)

$global:fabricHeaders = @{}

function SetFabricHeaders() {
    $global:fabricHeaders = @{
        'Content-Type' = "application/json"
        'Authorization' = "Bearer {0}" -f $fabricToken
    }
}

function GetWorkspaceByName($workspaceName) {
    # Get workspaces
    $getWorkspacesUrl = "{0}/workspaces" -f $baseUrl
    Write-Host "getWorkspacesUrl: $getWorkspacesUrl"
    $workspaces = (Invoke-RestMethod -Headers $global:fabricHeaders -Uri $getWorkspacesUrl -Method GET).value

    # Try to find the workspace by display name
    $workspace = $workspaces | Where-Object {$_.DisplayName -eq $workspaceName}

    return $workspace
}

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
    SetFabricHeaders

    $workspace = GetWorkspaceByName $workspaceName

    # Verify the existence of the requested workspace
    if(!$workspace) {
        Write-Host "A workspace with the requested name was not found." -ForegroundColor Red
        return
    }

    # Get Status
    Write-Host "Calling GET Status REST API to construct the request body for UpdateFromGit REST API."

    $gitStatusUrl = "{0}/workspaces/{1}/git/status" -f $baseUrl, $workspace.Id
    $gitStatusResponse = Invoke-RestMethod -Headers $global:fabricHeaders -Uri $gitStatusUrl -Method GET

    # Update from Git
    Write-Host "Updating the workspace '$workspaceName' from Git."

    $updateFromGitUrl = "{0}/workspaces/{1}/git/updateFromGit" -f $baseUrl, $workspace.Id

    $updateFromGitBody = @{ 
        remoteCommitHash = $gitStatusResponse.RemoteCommitHash
        workspaceHead = $gitStatusResponse.WorkspaceHead
        conflictResolution = @{
            conflictResolutionType = "Workspace"
            conflictResolutionPolicy = "PreferRemote"
        }
        options = @{
            # Allows overwriting existing items if needed
            allowOverrideItems = $TRUE
        }
    } | ConvertTo-Json

    $updateFromGitResponse = Invoke-WebRequest -Headers $global:fabricHeaders -Uri $updateFromGitUrl -Method POST -Body $updateFromGitBody

    $operationId = $updateFromGitResponse.Headers['x-ms-operation-id']
    $retryAfter = $updateFromGitResponse.Headers['Retry-After']
    Write-Host "Long running operation Id: '$operationId' has been scheduled for updating the workspace '$workspaceName' from Git with a retry-after time of '$retryAfter' seconds." -ForegroundColor Green

    # Poll Long Running Operation
    $getOperationState = "{0}/operations/{1}" -f $baseUrl, $($operationId)
    Write-Host "Long operation state '$getOperationState' ."
    do
    {
        $operationState = Invoke-RestMethod -Headers $fabricHeaders -Uri $getOperationState -Method GET
        Write-Host "Update  '$pipelineName' operation status: $($operationState.Status)"
        if ($operationState.Status -in @("NotStarted", "Running")) {
            Start-Sleep -Seconds $($retryAfter)
        }
    } while($operationState.Status -in @("NotStarted", "Running"))
    if ($operationState.Status -eq "Failed") {
        Write-Host "Failed to update the workspace '$workspaceName' from Git. Error reponse: $($operationState.Error | ConvertTo-Json)" -ForegroundColor Red
    }
    else{
        Write-Host "The workspace '$workspaceName' has been successfully updated from Git." -ForegroundColor Green
    }

} catch {
    $errorResponse = GetErrorResponse($_.Exception)
    Write-Host "Failed to update the workspace '$workspaceName' from Git. Error reponse: $errorResponse" -ForegroundColor Red
}
