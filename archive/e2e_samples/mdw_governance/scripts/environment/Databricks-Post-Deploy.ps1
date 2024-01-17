function clusterExists 
    ([parameter(Mandatory = $true)] [String] $clusterName)
{    
    $clusters=$(databricks clusters list --output JSON| ConvertFrom-Json)
    $filteredData = $clusters.clusters | Where-Object cluster_name -eq $clusterName
    return $filteredData
}

function waitForCluster
([parameter(Mandatory = $true)] [String] $clusterId)
{
    while($true) {
        $clusterState=$(databricks clusters get --cluster-id $clusterId |  ConvertFrom-Json).state
        if ($clusterState -like "*RUNNING*") {
            break;
        }
        elseif ($clusterState -like "*TERMINATED*" -Or $clusterState -like "*ERROR*") {
            $stateMessage=$(databricks clusters get --cluster-id $clusterId |  ConvertFrom-Json).state_message
            Write-Error "Error in cluster $($clusterId): $($stateMessage)"
            Exit
        }
        else{
            Write-Information "Waiting for cluster $($clusterId) to run..."
            Start-Sleep -s 60 
        }
    }
}

function waitForRun 
    ([parameter(Mandatory = $true)] [String] $runId)
{
    while($true) {
        $lifeCycleStatus=$(databricks runs get --run-id $runId |  ConvertFrom-Json).state.life_cycle_state
        $resultState=$(databricks runs get --run-id $runId |  ConvertFrom-Json).state.result_state
        if ($resultState -like "*SUCCESS*" -Or $resultState -like "*SKIPPED*") {
            break;
        }
        elseif ($lifeCycleStatus -like "*INTERNAL_ERROR*" -Or $resultState -like "*FAILED*") {
            $stateMessage=$(databricks runs get --run-id $runId | ConvertFrom-Json).state.state_message
            Write-Error "Error while running $($runId): $($stateMessage)"
            Exit
        }
        else{
            Write-Information "Waiting for run $($mount_run_id) to finish..."
            Start-Sleep -s 60 
        }
    }
}

function getPat
 ([parameter(Mandatory = $true)] [String] $message)
{
    Write-Information "Generating a Databricks PAT token"

    $databricksGlobalToken=(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json |  ConvertFrom-Json).accessToken
    $databricksHost="https://$($env:DATABRICKS_WORKSPACE_URL)"

    $env:DATABRICKS_HOST = $databricksHost
    $azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | ConvertFrom-Json).accessToken
    $headers = @{
        Authorization = "Bearer $($databricksGlobalToken)";
        'X-Databricks-Azure-SP-Management-Token' = $azureApiToken
        'X-Databricks-Azure-Workspace-Resource-Id' = $env:DATABRICKS_WORKSPACE_ID
        }
    $databricksManagementUri="$($databricksHost)/api/2.0/token/create"
    $databricksToken=(Invoke-WebRequest -Uri $databricksManagementUri -Method POST -Headers $headers -Body "{ ""comment"": ""$message"" }" | ConvertFrom-Json).token_value
    $env:DATABRICKS_TOKEN = $databricksToken
}
# set databricks token to env variable
getPat -message "For Deployment"

# Getting storage primary key
$storagePrimaryKey=$(az storage account keys list -g $env:RESOURCE_GROUP_NAME -n $env:STORAGE_ACCOUNT_NAME --output json| ConvertFrom-Json)[0].value


Write-Information "Waiting for Databricks workspace to be ready..."
Start-Sleep -s 180

Write-Information "Configuring Databricks workspace."

# Setting up databricks backed secret scope and secrets
# prefer AKV, but cannot use service principal for it: https://github.com/MicrosoftDocs/azure-docs/issues/65000
databricks secrets create-scope --scope storage_scope --initial-manage-principal users
databricks secrets put --scope storage_scope --key storage_account_access_key --string-value $storagePrimaryKey

# Upload the init script to the file system
databricks fs cp "./databricks/setup/startup.sh" "dbfs:/FileStore/dependencies/startup.sh"

# Upload notebooks
Write-Information "Uploading notebooks..."
databricks workspace import_dir "./databricks/notebooks" "/notebooks" --overwrite

# Create Cluster
$clusterConfig=(Get-Content "./databricks/config/cluster.config.json" -raw | ConvertFrom-Json)
$clusterName=$clusterConfig.cluster_name

Write-Information "Creating a cluster using config in $($clusterConfigString)..."
if (clusterExists -clusterName $clusterName) { 
    Write-Information "Cluster $($clusterName) already exists!"
    $clusterId = $(databricks clusters get --cluster-name $clusterName | ConvertFrom-Json).cluster_id
}
else {
    Write-Information "Creating cluster $($clusterName). This may take a while as cluster spins up..."
    $clusterConfig.spark_env_vars.STORAGE_ACCOUNT_NAME=$env:STORAGE_ACCOUNT_NAME
    $clusterConfig.spark_env_vars.STORAGE_CONTAINER_NAME=$env:STORAGE_CONTAINER_NAME
    $clusterConfigString=($clusterConfig | ConvertTo-Json -Depth 3) -replace '"','\"'
    $clusterId = $(databricks clusters create --json ""$clusterConfigString"" | ConvertFrom-Json).cluster_id
    Write-Information "Waiting for Databricks cluster to be ready..."
    waitForCluster -clusterId $clusterId
}

# Setup mount by running notebook
$runConfig=(Get-Content "./databricks/config/run.setup.config.json" -raw | ConvertFrom-Json)
$runConfig.existing_cluster_id=$clusterId
$runConfigString=($runConfig | ConvertTo-Json) -replace '"','\"'
Write-Information "Setting up mounts with $($runConfigString)."
waitForRun -runId  $(databricks runs submit --json ""$runConfigString"" | ConvertFrom-Json).run_id

# Setting up environment vars
Write-Host "##vso[task.setvariable variable=databricksClusterId;]$clusterId"

# Add PAT to AKV
getPat -message "For ADF"
az keyvault secret set --name $env:DATABRICKS_TOKEN_SECRET_NAME --vault-name $env:KEYVAULT_NAME --value $env:DATABRICKS_TOKEN
