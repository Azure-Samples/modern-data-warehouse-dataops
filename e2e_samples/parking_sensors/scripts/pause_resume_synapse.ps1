# PowerShell script to Pause or Resume Azure Synapse SQL Pools and Azure SQL Data Warehouse (Dedicated SQL Pools).
# Requires Azure CLI installed and logged in.

param(
    [string]$SubscriptionId,
    [string]$DeploymentIds,
    [string]$Project,
    [string]$Environments = "dev,stg,prod",
    [string]$ResourceGroups,
    [string]$Action = "Pause",
    [switch]$DryRun
)

# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\Script.ps1 -SubscriptionId <SUBSCRIPTION_ID> [-DeploymentIds <IDs>] -Project <PROJECT> -Environments <ENVIRONMENTS>`n[-ResourceGroups <GROUPS>] -Action <Pause|Resume> [-DryRun]" -ForegroundColor Yellow
    Write-Host "  -SubscriptionId            Azure Subscription ID (required)."
    Write-Host "  -DeploymentIds             Deployment IDs (comma-separated, required if ResourceGroups is not specified)."
    Write-Host "  -Project                   Project name (required if ResourceGroups is not specified)."
    Write-Host "  -Environments              Environments (default: dev,stg,prod)."
    Write-Host "  -ResourceGroups            Resource groups override (comma-separated)."
    Write-Host "  -Action                    Action to perform: Pause or Resume (default: Pause)."
    Write-Host "  -DryRun                    Simulate actions without making any changes."
    exit 1
}

# Validate required parameters
if (-not $SubscriptionId) {
    Write-Host "ERROR: SubscriptionId is required." -ForegroundColor Red
    Show-Usage
}

if (-not $ResourceGroups -and (-not $DeploymentIds -or -not $Project)) {
    Write-Host "ERROR: DeploymentIds and Project are required if ResourceGroups is not specified." -ForegroundColor Red
    Show-Usage
}

# Generate or override resource group names
$ResourceGroupsList = @()
if ($ResourceGroups) {
    $ResourceGroupsList = $ResourceGroups -split ','
} else {
    foreach ($env in $Environments -split ',') {
        foreach ($deploymentId in $DeploymentIds -split ',') {
            $env = $env.Trim()  # Ensure no extra spaces
            $deploymentId = $deploymentId.Trim()  # Ensure no extra spaces
            $ResourceGroupsList += "${Project}-${deploymentId}-dbw-${env}-rg"
            $ResourceGroupsList += "${Project}-${deploymentId}-${env}-rg"
        }
    }
}

Write-Host "INFO: Using Resource Groups: $($ResourceGroupsList -join ', ')" -ForegroundColor Green

# Set Azure subscription
az account set --subscription $SubscriptionId

# Function to process Synapse SQL Pools
function Process-SynapseSqlPool {
    param (
        [string]$ResourceGroup,
        [string]$Action
    )

    $workspaces = az synapse workspace list --resource-group $ResourceGroup --query "[].name" -o tsv 2>$null
    if (-not $workspaces) {
        Write-Host "WARNING: No Synapse Workspaces found in Resource Group: $ResourceGroup" -ForegroundColor Yellow
        return
    }

    foreach ($workspace in $workspaces) {
        Write-Host "  INFO: Checking Workspace: $workspace" -ForegroundColor Green

        $sqlPools = az synapse sql pool list --workspace-name $workspace --resource-group $ResourceGroup --query "[].{name:name,status:status}" -o tsv
        if (-not $sqlPools) {
            Write-Host "    WARNING: No SQL Pools found in Workspace: $workspace" -ForegroundColor Yellow
            continue
        }

        foreach ($sqlPool in $sqlPools) {
            $poolName, $poolStatus = $sqlPool -split "\t"
            Write-Host "    INFO: SQL Pool: $poolName (Status: $poolStatus)" -ForegroundColor Green

            if (($Action -eq "Pause" -and $poolStatus -eq "Online") -or ($Action -eq "Resume" -and $poolStatus -eq "Paused")) {
                Write-Host "      $Action-ing Synapse SQL Pool: $poolName" -ForegroundColor Green
                if (-not $DryRun) {
                    if ($Action -eq "Pause") {
                        az synapse sql pool pause --name $poolName --workspace-name $workspace --resource-group $ResourceGroup
                    } else {
                        az synapse sql pool resume --name $poolName --workspace-name $workspace --resource-group $ResourceGroup
                    }
                    Write-Host "      Successfully $Action-ed Synapse SQL Pool: $poolName" -ForegroundColor Green
                } else {
                    Write-Host "      Dry Run: Would have $Action-ed Synapse SQL Pool: $poolName" -ForegroundColor Green
                }
            } else {
                Write-Host "      SQL Pool: $poolName is already in the desired state." -ForegroundColor Green
            }
        }
    }
}

# Function to process Azure SQL Data Warehouse (Dedicated SQL Pools)
function Process-SqlDatabase {
    param (
        [string]$ResourceGroup,
        [string]$Action
    )

    $sqlServers = az sql server list --resource-group $ResourceGroup --query "[].name" -o tsv 2>$null
    if (-not $sqlServers) {
        Write-Host "WARNING: No SQL Servers found in Resource Group: $ResourceGroup" -ForegroundColor Yellow
        return
    }

    foreach ($server in $sqlServers) {
        Write-Host "  INFO: Checking SQL Server: $server" -ForegroundColor Green

        $sqlDws = az sql dw list --server $server --resource-group $ResourceGroup --query "[].{name:name,status:status}" -o tsv
        if (-not $sqlDws) {
            Write-Host "    WARNING: No Dedicated SQL Pools found on Server: $server" -ForegroundColor Yellow
            continue
        }

        foreach ($sqlDw in $sqlDws) {
            $dwName, $dwStatus = $sqlDw -split "\t"
            Write-Host "    INFO: Dedicated SQL Pool: $dwName (Status: $dwStatus)" -ForegroundColor Green

            if (($Action -eq "Pause" -and $dwStatus -eq "Online") -or ($Action -eq "Resume" -and $dwStatus -eq "Paused")) {
                Write-Host "      $Action-ing Dedicated SQL Pool: $dwName" -ForegroundColor Green
                if (-not $DryRun) {
                    if ($Action -eq "Pause") {
                        az sql dw pause --name $dwName --server $server --resource-group $ResourceGroup
                    } else {
                        az sql dw resume --name $dwName --server $server --resource-group $ResourceGroup
                    }
                    Write-Host "      Successfully $Action-ed Dedicated SQL Pool: $dwName" -ForegroundColor Green
                } else {
                    Write-Host "      Dry Run: Would have $Action-ed Dedicated SQL Pool: $dwName" -ForegroundColor Green
                }
            } else {
                Write-Host "      Dedicated SQL Pool: $dwName is already in the desired state." -ForegroundColor Green
            }
        }
    }
}

# Process each resource group
foreach ($resourceGroup in $ResourceGroupsList) {
    if (-not (az group show --name $resourceGroup 2>$null)) {
        Write-Host "ERROR: Resource Group [$resourceGroup] does not exist. Skipping." -ForegroundColor Red
        continue
    }

    Write-Host "INFO: Processing Resource Group: $resourceGroup" -ForegroundColor Green
    Write-Host "----------------------------------------"

    # Process Synapse SQL Pools
    Process-SynapseSqlPool -ResourceGroup $resourceGroup -Action $Action

    # Process Azure SQL Data Warehouse (Dedicated SQL Pools)
    Process-SqlDatabase -ResourceGroup $resourceGroup -Action $Action
}
