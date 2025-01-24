# PowerShell script to Pause or Resume Azure Synapse SQL Pools and Azure SQL Data Warehouse (Dedicated SQL Pools).
# Supports both Azure Automation (Managed Identity) and local manual execution.

param(
    [string]$SubscriptionId,
    [string]$DeploymentIds,
    [string]$Project,
    [string]$Environments = "dev,stg",
    [string]$ResourceGroups,
    [ValidateSet("Pause", "Resume")]
    [string]$Action = "Pause",
    [switch]$DryRun
)

# Initialize error and warning tracking
[int]$global:iWarningCount = 0
[int]$global:iErrorCount = 0
$ErrorActionPreference = "Continue"

# Function to log messages and handle error/warning counters
function Log-Message {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "ERROR" {
            $global:iErrorCount++
            Write-Error "$timestamp [$Level] $Message"
        }
        "WARNING" {
            $global:iWarningCount++
            Write-Warning "$timestamp [$Level] $Message"
        }
        default {
            Write-Output "$timestamp [$Level] $Message"
        }
    }
}


# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\pause_resume_synapse.ps1 -SubscriptionId <SUBSCRIPTION_ID> [-DeploymentIds <IDs>] -Project <PROJECT> -Environments <ENVIRONMENTS>`n[-ResourceGroups <GROUPS>] -Action <Pause|Resume> [-DryRun]" -ForegroundColor Yellow
    Write-Host "  -SubscriptionId            Azure Subscription ID (required for manual run)."
    Write-Host "  -ResourceGroups            Resource groups (comma-separated, use '*' to target all resource groups)."
    Write-Host "  -DeploymentIds             Deployment IDs for resource group generation (comma-separated, required if ResourceGroups is not specified)."
    Write-Host "  -Project                   Project name for resource group generation (required if ResourceGroups is not specified)."
    Write-Host "  -Environments              Environments for resource group generation (comma-separated, required if ResourceGroups is not specified) (default: dev,stg)"
    Write-Host "  -Action                    Action to perform: Pause or Resume (default: Pause)."
    Write-Host "  -DryRun                    Simulate actions without making any changes (default: false)."
    exit 1
}

# Trim unnecessary spaces from parameters
$SubscriptionId = $SubscriptionId.Trim()
$DeploymentIds = $DeploymentIds.Trim()
$Project = $Project.Trim()
$Environments = $Environments.Trim()
$ResourceGroups = $ResourceGroups.Trim()
$Action = $Action.Trim()

# Validate Action parameter
if ($Action -notin @("Pause", "Resume")) {
    Log-Message "ERROR: Invalid action '$Action'. Valid actions are 'Pause' or 'Resume'." "ERROR"
    Show-Usage
}

# Ensure Az modules are installed and imported
$modules = @("Az.Accounts", "Az.Sql", "Az.Synapse", "Az.Resources")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Log-Message "Installing module $module..." "INFO"
        Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber
    }
    Import-Module $module -ErrorAction Stop
}

# Authenticate and set subscription context
try {
    if ($env:MSI_SECRET) {
        Log-Message "Running in Azure Automation. Authenticating with Managed Identity." "INFO"
        Connect-AzAccount -Identity -ErrorAction Stop
    } else {
        Log-Message "Running locally. Using manual authentication." "INFO"
        $Context = Get-AzContext
        if (-not $Context) {
            Log-Message "No existing context. Logging in..." "INFO"
            Connect-AzAccount -ErrorAction Stop
        } else {
            Log-Message "Existing context detected. Account: $($Context.Account.Id)" "INFO"
        }
    }

    if (-not $SubscriptionId) {
        $Subscriptions = Get-AzSubscription -ErrorAction Stop
        if (-not $Subscriptions) {
            Log-Message "No subscriptions are accessible." "ERROR"
            Show-Usage
        }
        $SubscriptionId = $Subscriptions[0].Id
        Log-Message "No subscription specified. Defaulting to: $SubscriptionId" "INFO"
    }

    Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    Log-Message "Subscription context set to: $SubscriptionId" "INFO"
} catch {
    Log-Message "Authentication or subscription setup failed: $_" "ERROR"
    Show-Usage
}

# Determine resource groups
$ResourceGroupsList = @()

if ($ResourceGroups -eq '*') {
    try {
        $ResourceGroupsList = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName
        Log-Message "Targeting all resource groups in the subscription." "INFO"
    } catch {
        Log-Message "Failed to retrieve resource groups: $_" "ERROR"
        exit 1
    }
} elseif ($ResourceGroups -and $ResourceGroups -ne "") {
    $ResourceGroupsList = $ResourceGroups -split ','
} elseif ($Project -and $DeploymentIds) {
    foreach ($env in $Environments -split ',') {
        foreach ($deploymentId in $DeploymentIds -split ',') {
            $ResourceGroupsList += "${Project}-${deploymentId}-dbw-${env}-rg"
            $ResourceGroupsList += "${Project}-${deploymentId}-${env}-rg"
        }
    }
} else {
    Log-Message "No resource groups provided or generated." "ERROR"
    Show-Usage
}

Log-Message "Resource Groups to process: $($ResourceGroupsList -join ', ')" "INFO"

# Function to process Synapse SQL Pools
function Process-SynapseSqlPool {
    param (
        [string]$ResourceGroup,
        [string]$Action
    )

    try {
        $workspaces = Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroup | Select-Object -ExpandProperty Name
        if (-not $workspaces) {
            Log-Message "WARNING: No Synapse Workspaces found in Resource Group: $ResourceGroup" "WARNING"
            return
        }
    } catch {
        Log-Message "ERROR: Failed to retrieve Synapse Workspaces for Resource Group: $ResourceGroup. $_" "ERROR"
        return
    }

    foreach ($workspace in $workspaces) {
        Log-Message "INFO: Checking Synapse Workspace: $workspace for SQL Pools" "INFO"

        try {
            $sqlPools = Get-AzSynapseSqlPool -ResourceGroupName $ResourceGroup -WorkspaceName $workspace
            if (-not $sqlPools) {
                Log-Message "WARNING: No SQL Pools found in Workspace: $workspace" "WARNING"
                continue
            }
        } catch {
            Log-Message "ERROR: Failed to retrieve SQL Pools for Workspace: $workspace. $_" "ERROR"
            continue
        }

        foreach ($sqlPool in $sqlPools) {
            $poolName = $sqlPool.Name
            $poolStatus = $sqlPool.Status

            if ($poolStatus -eq "Paused") {
                Log-Message "INFO: SQL Pool: $poolName is already paused. Skipping." "INFO"
            } elseif ($poolStatus -eq "Online") {
                Log-Message "INFO: SQL Pool: $poolName is online. Initiating $Action..." "INFO"

                try {
                    if (-not $DryRun) {
                        if ($Action -eq "Pause") {
                            Suspend-AzSynapseSqlPool -Name $poolName -WorkspaceName $workspace -ResourceGroupName $ResourceGroup
                        } elseif ($Action -eq "Resume") {
                            Resume-AzSynapseSqlPool -Name $poolName -WorkspaceName $workspace -ResourceGroupName $ResourceGroup
                        }
                    }
                    Log-Message "Successfully $Action-ed SQL Pool: $poolName." "INFO"
                } catch {
                    Log-Message "ERROR: Failed to $Action SQL Pool: $poolName. $_" "ERROR"
                }
            } else {
                Log-Message "WARNING: SQL Pool: $poolName is in an unsupported state: $poolStatus" "WARNING"
            }
        }
    }
}

# Function to process Azure SQL Data Warehouses
function Process-SqlDatabase {
    param (
        [string]$ResourceGroup,
        [string]$Action
    )

    try {
        $sqlServers = Get-AzSqlServer -ResourceGroupName $ResourceGroup | Select-Object -ExpandProperty ServerName
        if (-not $sqlServers) {
            Log-Message "WARNING: No SQL Servers found in Resource Group: $ResourceGroup" "WARNING"
            return
        }
    } catch {
        Log-Message "ERROR: Failed to retrieve SQL Servers for Resource Group: $ResourceGroup. $_" "ERROR"
        return
    }

    foreach ($server in $sqlServers) {
        Log-Message "INFO: Checking SQL Server: $server in Resource Group: $ResourceGroup" "INFO"

        try {
            $sqlDws = Get-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $server | Where-Object { $_.Edition -eq "DataWarehouse" }
            if (-not $sqlDws) {
                Log-Message "WARNING: No Dedicated SQL Pools found on Server: $server" "WARNING"
                continue
            }
        } catch {
            Log-Message "ERROR: Failed to retrieve Dedicated SQL Pools for Server: $server. $_" "ERROR"
            continue
        }

        foreach ($sqlDw in $sqlDws) {
            $dwName = $sqlDw.DatabaseName
            $dwStatus = $sqlDw.Status

            if ($dwStatus -eq "Paused") {
                Log-Message "INFO: Dedicated SQL Pool: $dwName is already paused." "INFO"
            } elseif ($dwStatus -eq "Online") {
                Log-Message "INFO: Dedicated SQL Pool: $dwName is online. Initiating $Action..." "INFO"

                try {
                    if (-not $DryRun) {
                        if ($Action -eq "Pause") {
                            Suspend-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $server -DatabaseName $dwName
                        } elseif ($Action -eq "Resume") {
                            Resume-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $server -DatabaseName $dwName
                        }
                    }
                    Log-Message "Successfully $Action-ed Dedicated SQL Pool: $dwName." "INFO"
                } catch {
                    Log-Message "ERROR: Failed to $Action Dedicated SQL Pool: $dwName. $_" "ERROR"
                }
            } else {
                Log-Message "WARNING: Dedicated SQL Pool: $dwName is in an unsupported state: $dwStatus" "WARNING"
            }
        }
    }
}

# Process each resource group
foreach ($resourceGroup in $ResourceGroupsList) {
    try {
        # Attempt to get the resource group with localized error handling
        $rgExists = Get-AzResourceGroup -Name $resourceGroup -ErrorAction Stop
        Log-Message "-----------------------------------------------" "INFO"
        Log-Message "INFO: Processing Resource Group: $($rgExists.ResourceGroupName) in location: $($rgExists.Location)" "INFO"
        Log-Message "-----------------------------------------------" "INFO"

        # Process Synapse SQL Pools
        Process-SynapseSqlPool -ResourceGroup $resourceGroup -Action $Action

        # Process Azure SQL Data Warehouse
        Process-SqlDatabase -ResourceGroup $resourceGroup -Action $Action
    } catch {
        # Log the error but don't exit the script
        Log-Message "ERROR: Resource Group [$resourceGroup] does not exist or is inaccessible. $_" "ERROR"
        continue
    }
}


# Final error and warning summary
Log-Message "Script completed with $global:iErrorCount error(s) and $global:iWarningCount warning(s)." "INFO"