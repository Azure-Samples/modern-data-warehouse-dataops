param
(
    [parameter(Mandatory = $true)] [String] $baseUrl,
    [parameter(Mandatory = $true)] [String] $fabricToken,
    [parameter(Mandatory = $true)] [String] $workspaceName,      # The name of the workspace,
    [parameter(Mandatory = $true)] [String] $capacityId,         # The capacity id of the workspace,
    [parameter(Mandatory = $true)] [String] $folder,             # The folder where the workspace items are located on the branch, should be: Join-Path $(Build.SourcesDirectory) $(directory_name)
    [parameter(Mandatory = $false)] [bool] $resetConfig=$false   # Used when the developer wants to reset the config files in the workspace (typically when a new feature branch is created)
)
## FROM GIT TO WORKSPACE
# Used when the developer creates a new branch from the development/main branch
# and wants to create or update the workspace in accordance with the new branch.


function GetErrorResponse($exception) {
    # Relevant only for PowerShell Core
    if ($exception.Exception.Response) {
        return $exception.Exception.Message
    }
    else {
        $errorResponse = $_
    }
    
    if(!$errorResponse) {
        # This is needed to support Windows PowerShell
        $result = $exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $errorResponse = $reader.ReadToEnd();
    }

    return $errorResponse
}

function getorCreateWorkspaceId($requestHeader, $contentType, $baseUrl, $workspaceName, $capacityId){
    $params = @{
        Uri = "$($baseUrl)/workspaces"
        Method = "GET"
        Headers = $requestHeader
        ContentType = $contentType
    }
    $workspaces = (Invoke-RestMethod @params).value
    $workspace = $workspaces | Where-Object {$_.displayName -eq $workspaceName}
    if(!$workspace) {
        Write-Host "A workspace with the requested name $workspaceName was not found, creating new workspace." -ForegroundColor Yellow
        $params = @{
            Uri = "$($baseUrl)/workspaces"
            Method = "POST"
            Headers = $requestHeader
            ContentType = $contentType
            Body = @{
                displayName = $workspaceName
                capacityId = $capacityId
            } | ConvertTo-Json
        }
        $workspace = (Invoke-RestMethod @params)
        Write-Host "Workspace $workspaceName with id $($workspace.id) was created." -ForegroundColor Green
        return $workspace.id
    }
    else {
        Write-Host "Workspace $workspaceName with id $($workspace.id) was found." -ForegroundColor Green
        return $workspace.id
    }
}

function createWorkspaceItem($baseUrl, $workspaceId, $requestHeader, $contentType, $itemMetadata, $itemDefinition){
    if ($itemDefinition)
    {
        # if the item has a definition create the item with definition
        $body = @{
            displayName = $itemMetadata.displayName
            description = $itemMetadata.description
            type = $itemMetadata.type
            definition = $itemDefinition.definition
        }
    }
    else { #item does not have definition, only create the item with metadata
        $body = @{
            displayName = $itemMetadata.displayName
            description = $itemMetadata.description
            type = $itemMetadata.type
        }
    }
    $params = @{
        Uri = "$($baseUrl)/workspaces/$($workspaceId)/items"
        Method = "POST"
        Headers = $requestHeader
        ContentType = $contentType
        Body = $body | ConvertTo-Json -Depth 10
    }

    $item = (Invoke-RestMethod @params -ResponseHeadersVariable responseHeaders -StatusCodeVariable statusCode)
    if ($statusCode -eq 202) { # status 202 is accepted instead of OK, which signals a long running operation
        $item = (longRunningOperationPolling $responseHeaders.Location $responseHeaders.'Retry-After')
    }

    Write-Host "Sensitivity Labels won't make future item defintion updates possible. Please update Sensitivity Labels for created items before re-running this script." -ForegroundColor Yellow
    return $item
}

function updateWorkspaceItemDefinition($baseUrl, $workspaceId, $requestHeader, $contentType, $itemMetadata, $itemDefinition, $itemConfig){
        $uri = "$($baseUrl)/workspaces/$($workspaceId)/items/$($itemConfig.objectId)/updateDefinition"
        if ($itemMetadata.type -eq "Notebook" -and !$itemDefinition.definition.format)
        {
            $itemDefinition.definition | Add-Member -Name "format" -value "ipynb" -MemberType NoteProperty -Force
        }
        $body = @{
            definition = $itemDefinition.definition
        }

        Write-Host "Executing POST to update definition of item $($itemConfig.objectId) $($itemMetadata.displayName)" -ForegroundColor Green
        # update the item definition
        $params = @{
            Uri = $uri
            Method = "POST"
            Headers = $requestHeader
            ContentType = $contentType
            Body = $body | ConvertTo-Json -Depth 10
        }
        Invoke-RestMethod @params -ResponseHeadersVariable responseHeaders -StatusCodeVariable statusCode
        if ($statusCode -eq 202 -and $responseHeaders.Location -and $responseHeaders.'Retry-After') { # status 202 is accepted instead of OK, which signals a long running operation
            longRunningOperationPolling $responseHeaders.Location $responseHeaders.'Retry-After'
        } 
}

function updateWorkspaceItem($baseUrl, $workspaceId, $requestHeader, $contentType, $itemMetadata, $itemDefinition, $itemConfig){
    # Start updating the item metadata
    $uri = "$($baseUrl)/workspaces/$($workspaceId)/items/$($itemConfig.objectId)"
    $body = @{
        displayName = $itemMetadata.displayName
        description = $itemMetadata.description
    }

    $params = @{
        Uri = $uri
        Method = "PATCH"
        Headers = $requestHeader
        ContentType = $contentType
        Body = $body | ConvertTo-Json -Depth 10
    }

    Write-Host "Executing PATCH to update item $($itemConfig.objectId) $($itemMetadata.displayName)" -ForegroundColor Green
    Invoke-RestMethod @params
    if ($itemDefinition) #for items with a definition, also update the definition
    {
        updateWorkspaceItemDefinition $baseUrl $workspaceId $requestHeader $contentType $itemMetadata $itemDefinition $itemConfig
    }
}

function createOrUpdateWorkspaceItem($requestHeader, $contentType, $baseUrl, $workspaceId, $workspaceItems, $folder, $repoItems){
    # Find if the item already exists in the workspace looking at the $itemConfigFileName file
    $metadataFilePath = Join-Path $folder $itemMetadataFileName
    if ([System.IO.File]::Exists($metadataFilePath)){
        $itemMetadata = Get-Content -Path $metadataFilePath -Raw | ConvertFrom-Json
        Write-Host "Found item metadata for $($itemMetadata.displayName)" -ForegroundColor Green
    }
    else {
        Write-Host "Item $folder does not have the required metadata file, skipping." -ForegroundColor Yellow
        return
    }
    $definitionFilePath = Join-Path $folder $itemDefinitionFileName
    if ([System.IO.File]::Exists($definitionFilePath)){
        $itemDefinition = Get-Content -Path $definitionFilePath -Raw | ConvertFrom-Json
        Write-Host "Found item definition for $($itemMetadata.displayName)" -ForegroundColor Green
        $contentFiles = Get-ChildItem -Path $folder | Where-Object {$_.Name -notlike $itemMetadataFileName -and $_.Name -notlike $itemDefinitionFileName -and $_.Name -notlike $itemConfigFileName}
        #$contentFiles = Get-ChildItem -Path $folder | Where-Object {$_.Name -like "*content*"}
        if ($contentFiles -and $contentFiles.Count -ge 1){ # if there is at least a content file then update the definition payload
            Write-Host "Found $($contentFiles.Count) content file(s) for $($itemMetadata.displayName)" -ForegroundColor Green
            foreach ($part in $itemDefinition.definition.parts){
                $file = $contentFiles | Where-Object {$_.Name -eq $part.path}
                $itemContent = Get-Content -Path $file.FullName -Raw
                $byte_array = [System.Text.Encoding]::UTF8.GetBytes($itemContent)
                $base64 = [System.Convert]::ToBase64String($byte_array)
                $part.payload = $base64
            }
            $itemDefinition| ConvertTo-Json -Depth 10 | New-Item -Path $definitionFilePath -Force
            Write-Host "updated item definition payload with content file for $($itemMetadata.displayName)" -ForegroundColor Green
        }
        else {
            Write-Host "Missing content file or found more than one content file, skipping update definition for $folder." -ForegroundColor Yellow
            return
        }
    }

    $configFilePath = Join-Path $folder "$itemConfigFileName"
    if (![System.IO.File]::Exists($configFilePath) -or $resetConfig){
        # if the config file does not exist then create a new logicalId and save the new config file
        # then create a new item and save the returned objectId in the config file
        Write-Host "no $itemConfigFileName file found, creating new file." -ForegroundColor Yellow
        $itemConfig = @{
            logicalId = [guid]::NewGuid().ToString()
        }
        $itemConfig | ConvertTo-Json -Depth 10 | New-Item -Path $configFilePath -Force
    }
    else {
        $itemConfig = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json
        Write-Host "Found item config file for $folder. Item missing objectId? $(!$itemConfig.objectId). Item missing logicalId? $(!$itemConfig.logicalId)" -ForegroundColor Green
    }

    if (!$itemConfig.objectId) {
        # 3. if an objectId is not present and only a logicalId is present then
        # Create a new object and save the objectId in the config file
        Write-Host "Item $folder does not have an associated objectId, creating new Fabric item of type $($itemMetadata.type) with name $($itemMetadata.displayName)." -ForegroundColor Yellow

        $item = createWorkspaceItem $baseUrl $workspaceId $requestHeader $contentType $itemMetadata $itemDefinition
        
        Write-Host "item is $($item.displayName) with id $($item.id)"
        # update the config file with the returned objectId
        $itemConfig | add-member -Name "objectId" -value $item.id -MemberType NoteProperty -Force
        Write-Host "itemConfig objectId is $($itemConfig.objectId)"
        $itemConfig | ConvertTo-Json | Set-Content -Path $configFilePath
        $repoItems += $item.id
    }
    else { #there is already a corresponding item in the workspace, we need to update it
        # 1. if the file contains an objectId then it means there is an associated item in the workspace
        $item = $workspaceItems | Where-Object {$_.id -eq $itemConfig.objectId}
        if (!$item) { # the item might have been manually deleted from the workspace
            # if this fails it might be because the item has just been deleted and for some time the
            # old item name is still recognized as an existing item by Fabric and therefore the 
            # operation might fail because of name clashes
            Write-Host "Item $($itemConfig.objectId) of type $($itemMetadata.type) was not found in the workspace, creating new item." -ForegroundColor Yellow
            $item = createWorkspaceItem $baseUrl $workspaceId $requestHeader $contentType $itemMetadata $itemDefinition
            $itemConfig.objectId = $item.id
            $itemConfig | ConvertTo-Json | Set-Content -Path $configFilePath | Out-Null
            $repoItems += $itemConfig.objectId
        }
        else {
            $repoItems += $itemConfig.objectId
            Write-Host "Item $($itemConfig.objectId) of type $($item.type) was found in the workspace, updating item." -ForegroundColor Green
            updateWorkspaceItem $baseUrl $workspaceId $requestHeader $contentType $itemMetadata $itemDefinition $itemConfig
        }    
    }
    return $repoItems      
}

function longRunningOperationPolling($uri, $retryAfter){
    try {
        # Get Long Running Operation
        Write-Host "Polling long running operation ID $uri has been started with a retry-after time of $retryAfter seconds."
    
        $params = @{
            Uri = "$uri"
            Method = "GET"
            Headers = $requestHeader
            ContentType = $contentType
        }

        do
        {
            $operationState = (Invoke-RestMethod @params -ResponseHeadersVariable responseHeaders)
    
            Write-Host "Long running operation status: $($operationState.Status)"
    
            if ($operationState.Status -in @("NotStarted", "Running")) {
                Start-Sleep -Seconds 20
                # Start-Sleep -Seconds $retryAfter
            }
        } while($operationState.Status -in @("NotStarted", "Running"))
    
        if ($operationState.Status -eq "Failed") {
            Write-Host "The long running operation has been completed with failure. Error reponse: $($operationState.Error | ConvertTo-Json)" -ForegroundColor Red
        }
        else{
            Write-Host "The long running operation has been successfully completed." -ForegroundColor Green

            if ($responseHeaders.Location) {
                $uri = $responseHeaders.Location
            }
            else {
                return
            }
            $paramsResult = @{
                Uri = "$uri"
                Method = "GET"
                Headers = $requestHeader
                ContentType = $contentType
            }
            $item = (Invoke-RestMethod @paramsResult)
            return $item
        }
    } catch {
        $errorResponse = GetErrorResponse($_)
        Write-Host "The long running operation has been completed with failure. Error reponse: $errorResponse" -ForegroundColor Red
        exit 1
    }
}

try {
    # TODO: consider removing the logicalId from the file as it's not used today.
    Write-Host "this task is running Powershell version " $PSVersionTable.PSVersion
    Write-Host "the folder we are working on is $folder"
    Write-Host "Updating workspace items for workspace $workspaceName"

    $itemConfigFileName = "item-config.json"
    $itemMetadataFileName = "item-metadata.json"
    $itemDefinitionFileName = "item-definition.json"

    $authHeader = "Bearer $($fabricToken)"
    $requestHeader = @{
    Authorization = $authHeader
    }
    $contentType = "application/json"

    # 1. Check if a workspace with given name already exists, if not create a new one
    $workspaceId = getorCreateWorkspaceId $requestHeader $contentType $baseUrl $workspaceName $capacityId

    # 2. For every Fabric item on the branch, check if they exist in the workspace
    # first get a list of all items in the workspace
    $params = @{
        Uri = "$($baseUrl)/workspaces/$($workspaceId)/items"
        Method = "GET"
        Headers = $requestHeader
        ContentType = $contentType
    }
    $workspaceItems = (Invoke-RestMethod @params).value
    $repoItems = @() # keep track of found object ids (either from creation or config files) and remove all other object ids from the workspace
    # if they exist update them else create new ones
    $dir = Get-ChildItem -Path $folder -Recurse -Directory
    foreach ($d in $dir) { 
        Write-Host $d.FullName
        $repoItems = createOrUpdateWorkspaceItem $requestHeader $contentType $baseUrl $workspaceId $workspaceItems $d.FullName $repoItems
    }

    # 3. for items that are in the workspace but not in the repository (hence no folder), we need to delete them from the workspace
    # use $repoItems to keep track of found object ids (either from creation or config files) and remove all other object ids from the workspace
    foreach ($item in $workspaceItems){
        if ($item.id -notin $repoItems -and $item.type -notin @("SQLEndpoint", "SemanticModel")){ # SemanticModel and SQL Endpoint items should not be deleted
            Write-Host "Item $($item.id) $($item.displayName) is in the workspace but not in the repository, deleting." -ForegroundColor Yellow
            $params = @{
                Uri = "$($baseUrl)/workspaces/$($workspaceId)/items/$($item.id)"
                Method = "DELETE"
                Headers = $requestHeader
                ContentType = $contentType
            }
            Invoke-RestMethod @params
        }
    }
    Write-Host "Script execution completed successfully. Workspace items have been updated for workspace $workspaceName." -ForegroundColor Green
}
catch {
    $errorResponse = GetErrorResponse($_)
    Write-Host "Failed to run script to update workspace items for workspace $workspaceName. Error reponse: $errorResponse" -ForegroundColor Red
    exit 1
}