param
(
    [parameter(Mandatory = $true)] [String] $workspaceName      # The name of the workspace,
)
## FROM WORKSPACE TO GIT
# Used when the developers have finished working on their workspace and want to sync back to their branch.
# We assume the branch is checked out locally and the script is run from there before creating a PR.

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

function getWorkspaceId($requestHeader, $contentType, $baseUrl, $workspaceName){
    $params = @{
        Uri = "$($baseUrl)/workspaces"
        Method = "GET"
        Headers = $requestHeader
        ContentType = $contentType
    }
    $workspaces = (Invoke-RestMethod @params).value
    $workspace = $workspaces | Where-Object {$_.displayName -eq $workspaceName}
    if(!$workspace) {
        Write-Host "A workspace with the requested name $workspaceName was not found, please make sure you specify the right workspace name." -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host "Workspace $workspaceName with id $($workspace.id) was found." -ForegroundColor Green
        return $workspace.id
    }
}

function getRepositoryItems($folder) {
    $repoItems = @()
    $folders = Get-ChildItem -Path $folder -Recurse -Directory
    $configFiles = Get-ChildItem -Path $folder -Recurse -Filter $itemConfigFileName
    foreach ($folder in $folders) {
        $repoItem = @{objectId = $null; folder = $folder; done = $false}
        $configPath = $configFiles | Where-Object {(Split-Path $_.FullName -Parent) -eq $folder.FullName}
        if ($configPath) {
            $config = Get-Content -Path $configPath | ConvertFrom-Json
            $repoItem.objectId = $config.objectId
        }
        $repoItems += $repoItem
    }
    return $repoItems
}
function createOrUpdateRepositoryItem($requestHeader, $contentType, $baseUrl, $workspaceId, $workspaceItem, $folder, $repoItems){
    if ($workspaceItem.type -in @("SQLEndpoint", "SemanticModel")) {
        Write-Host "$workspaceItem.type items are not supported. Skipping..." -ForegroundColor Yellow
        return
    }

    Write-Host "Processing item $($workspaceItem.displayName) of type $($workspaceItem.type)"

    $itemDefinition = $null
    $itemMetadata = $null
    $itemConfig = $null

    # 1. check if the item already exists on the repo (see object id in config files)
    # 2. if it does, update its metadata file as well as the definition file and content file
    # 3. if it does not, create a new item (folder, config file, metadata file, definition file, content file)
    # create folder using displayName and type

    # find or create item folder
    if ($workspaceItem.id -in $repoItems.objectId) {
        $repoItem = $repoItems | Where-Object {$_.objectId -eq $workspaceItem.id}
        $itemFolder = $repoItem.folder
        $repoItem.done = $true
    }
    else {
        $itemFolder = Join-Path $folder "$($workspaceItem.displayName).$($workspaceItem.type)"
        if (!(Test-Path -Path $itemFolder -PathType Container)) {
            New-Item -Path $itemFolder -ItemType Directory | Out-Null
        }
    }

    # update or create config file
    $configFilePath = Join-Path $itemFolder $itemConfigFileName
    if (![System.IO.File]::Exists($configFilePath)){
        $itemConfig = @{
            objectId = $workspaceItem.id
            logicalId = [guid]::NewGuid().ToString()
        }
        $itemConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath
    }
    else {
        $itemConfig = Get-Content -Path $configFilePath | ConvertFrom-Json
        if (!$itemConfig.objectId) {
            $itemConfig | Add-Member -Name "objectId" -value $workspaceItem.id -MemberType NoteProperty -Force
            $itemConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath
        }
    }

    # update or create metadata file
    $params = @{
        Uri = "$($baseUrl)/workspaces/$($workspaceId)/items/$($workspaceItem.id)"
        Method = "GET"
        Headers = $requestHeader
        ContentType = $contentType
    }
    $itemMetadata = (Invoke-RestMethod @params)
    $itemMetadata = $itemMetadata | Select-Object -Property displayName, type, description
    $metadataFilePath = Join-Path $itemFolder $itemMetadataFileName
    $itemMetadata | ConvertTo-Json -Depth 10 | Set-Content -Path $metadataFilePath

    # update or create definition file except for Lakehouse items
    if (!($workspaceItem.type -eq "Lakehouse")){
        Write-Host "Getting definition for item $($workspaceItem.displayName) of type $($workspaceItem.type)"
        if ($workspaceItem.type -eq "Notebook") {
            $uri = "$($baseUrl)/workspaces/$($workspaceId)/items/$($workspaceItem.id)/getDefinition?format=ipynb"
        }
        else {
            $uri = "$($baseUrl)/workspaces/$($workspaceId)/items/$($workspaceItem.id)/getDefinition"
        }
        $params = @{
            Uri = $uri
            Method = "POST"
            Headers = $requestHeader
            ContentType = $contentType
        }
        $itemDefinition = (Invoke-RestMethod @params -ResponseHeadersVariable responseHeaders -StatusCodeVariable statusCode)
        if ($statusCode -eq 202) { # status 202 is accepted instead of OK, which signals a long running operation
            $itemDefinition = (longRunningOperationPolling $responseHeaders.Location $responseHeaders.'Retry-After')
        }

        if ($workspaceItem.type -eq "Notebook" -and !$itemDefinition.definition.format) { # if the format is not set, set it to ipynb
            $itemDefinition.definition | Add-Member -Name "format" -value "ipynb" -MemberType NoteProperty -Force
        }

        $definitionFilePath = Join-Path $itemFolder $itemDefinitionFileName
        $itemDefinition | ConvertTo-Json -Depth 10 | Set-Content -Path $definitionFilePath

        # update or create content file
        # decoding from base64 to file then save as content file
        foreach ($part in $itemDefinition.definition.parts) {
            $base64 = $part.payload
            $byte_array = [System.Convert]::FromBase64String($base64)
            $itemContent = [System.Text.Encoding]::UTF8.GetString($byte_array)
            $contentFilePath = Join-Path $itemFolder $part.path
            Set-Content -Path $contentFilePath -Value $itemContent -Encoding UTF8
        }
    }

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
    }
    catch {
        $errorResponse = GetErrorResponse($_)
        Write-Host "The long running operation has been completed with failure. Error reponse: $errorResponse" -ForegroundColor Red
        exit 1
    }
}



function loadEnvironmentVariables() {
    Write-Host "Loading environment file..."
    get-content config/.env | ForEach-Object {
        if ($_ -match '^#' -or [string]::IsNullOrWhiteSpace($_)) { return } # skip comments and empty lines
        $name, $value = $_.split('=')
        $value = $value.split('#')[0].trim() # to support commented env files
        $value = $value -replace '^"|"$' # remove leading and trailing double quotes
        set-content env:\$name $value
    }
    Write-Host "Finished loading environment file. \nFabric REST API endpoint is $env:FABRIC_API_BASEURL"    
}

try {
    loadEnvironmentVariables
    $baseUrl=$env:FABRIC_API_BASEURL
    $fabricToken=$env:FABRIC_USER_TOKEN
    $folder=$env:ITEMS_FOLDER

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
    $workspaceId = getWorkspaceId $requestHeader $contentType $baseUrl $workspaceName

    # get workspace items
    # 2. For every item on the branch, check if they exist in the workspace
    # first get a list of all items in the workspace
    $params = @{
        Uri = "$($baseUrl)/workspaces/$($workspaceId)/items"
        Method = "GET"
        Headers = $requestHeader
        ContentType = $contentType
    }
    $workspaceItems = (Invoke-RestMethod @params).value
    $repoItems = getRepositoryItems $folder # keep track of found objectIds (either from config files or creating files
    # and corresponding configs) and remove all other object ids from the workspace
    # if they exist update them else create new ones
    foreach ($item in $workspaceItems) {
        createOrUpdateRepositoryItem $requestHeader $contentType $baseUrl $workspaceId $item $folder $repoItems
    }

    # delete folders that are not in the workspace items
    foreach ($repoItem in ($repoItems | Where-Object {!$_.done})) {
        Write-Host "Deleting folder $($repoItem.folder)"
        Remove-Item -Path $repoItem.folder -Recurse -Force
    }
    Write-Host "Script execution completed successfully. Repository items have been updated from workspace $workspaceName." -ForegroundColor Green
}
catch {
    $errorResponse = GetErrorResponse($_)
    Write-Host "Failed to run script to update repository items for workspace $workspaceName. Error reponse: $errorResponse" -ForegroundColor Red
    exit 1
}