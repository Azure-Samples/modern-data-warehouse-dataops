# PowerShell script to deploy the Pause/Resume Synapse SQL Pools script to Azure Automation.
# Deploys the script as an Automation Runbook with Managed Identity and assigns required permissions.

param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName = "Automation-RG",
    [string]$AutomationAccountName = "SynapseAutomation",
    [string]$Location = "East US",
    [string]$RunbookName = "PauseResumeSynapse",
    [string]$ScriptPath = "./pause_resume_synapse.ps1",
    [string]$ScheduleName = "DailyPause",
    [datetime]$ScheduleStartTime = (Get-Date).AddDays(1).Date.ToUniversalTime(),
    [int]$ScheduleInterval = 1,
    [string]$ScheduleFrequency = "Day",
    [string]$ParameterResourceGroups,
    [string]$ParameterAction,
    [string]$ParameterEnvironments,
    [string]$ParameterProject,
    [string]$ParameterDeploymentIds,
    [switch]$DryRun,
    [switch]$InstallModules
)

# Initialize error and warning tracking
[int]$global:iWarningCount = 0
[int]$global:iErrorCount = 0
$ErrorActionPreference = "Stop"

# Trim unnecessary spaces from parameters
$SubscriptionId = $SubscriptionId.Trim()
$ResourceGroupName = $ResourceGroupName.Trim()
$AutomationAccountName = $AutomationAccountName.Trim()
$Location = $Location.Trim()
$RunbookName = $RunbookName.Trim()
$ScriptPath = $ScriptPath.Trim()
$ScheduleName = $ScheduleName.Trim()
$ScheduleFrequency = $ScheduleFrequency.Trim()
$ParameterResourceGroups = $ParameterResourceGroups.Trim()
$ParameterAction = $ParameterAction.Trim()
$ParameterEnvironments = $ParameterEnvironments.Trim()
$ParameterProject = $ParameterProject.Trim()
$ParameterDeploymentIds = $ParameterDeploymentIds.Trim()

# Ensure Az modules are installed and imported
$modules = @("Az.Accounts", "Az.Automation", "Az.Resources")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        if ($InstallModules) {
            Log-Message "Installing module $module..." "INFO"
            Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber
        } else {
            Log-Message "Module $module is missing. Use -InstallModules to install missing modules." "ERROR"
            exit 1
        }
    }
    Import-Module $module -ErrorAction Stop
}

# Function to log messages
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

# Function to show usage
function Show-Usage {
    Write-Host "Usage: .\deploy_pause_resume_synapse.ps1 -SubscriptionId <SUBSCRIPTION_ID> \`n-ResourceGroupName <RESOURCE_GROUP_NAME> -AutomationAccountName <AUTOMATION_ACCOUNT_NAME> \`n-Location <LOCATION> -RunbookName <RUNBOOK_NAME> -ScriptPath <SCRIPT_PATH> \`n-ScheduleName <SCHEDULE_NAME> -ScheduleStartTime <START_TIME> -ScheduleInterval <INTERVAL> \`n-ScheduleFrequency <FREQUENCY> -ParameterSubscriptionId <SUBSCRIPTION_ID> \`n-ParameterResourceGroups <RESOURCE_GROUPS> -ParameterAction <Pause|Resume> \`n-ParameterEnvironments <ENVIRONMENTS> -ParameterProject <PROJECT> \`n-ParameterDeploymentIds <DEPLOYMENT_IDS> [-DryRun]" -ForegroundColor Yellow
    Write-Host "  -SubscriptionId            Azure Subscription ID for deploying the runbook."
    Write-Host "  -ResourceGroupName         Name of the resource group where the Automation Account will reside. Default: Automation-RG."
    Write-Host "  -AutomationAccountName     Name of the Automation Account to be created or used. Default: SynapseAutomation."
    Write-Host "  -Location                  Azure region for the Automation Account. Default: East US."
    Write-Host "  -RunbookName               Name of the runbook to be created. Default: PauseResumeSynapse."
    Write-Host "  -ScriptPath                Path to the PowerShell script to import as a runbook. Default: ./pause_resume_synapse.ps1."
    Write-Host "  -ScheduleName              Name of the schedule to create. Default: DailyPauseResume."
    Write-Host "  -ScheduleStartTime         Start time for the schedule. Default: UTC midnight next day."
    Write-Host "  -ScheduleInterval          Interval for the schedule. Default: 1."
    Write-Host "  -ScheduleFrequency         Frequency for the schedule (e.g., Day, Week). Default: Day."
    Write-Host "  -ParameterResourceGroups   Resource groups to target (comma-separated, use '*' to target all resource groups)."
    Write-Host "  -ParameterAction           Action to perform: Pause or Resume."
    Write-Host "  -ParameterEnvironments     Environments for resource group generation (comma-separated, required if ParameterResourceGroups is not specified)."
    Write-Host "  -ParameterProject          Project name for resource group generation. Specific to Databricks E2E use case. (required if ParameterResourceGroups is not specified)."
    Write-Host "  -ParameterDeploymentIds    Deployment IDs for resource group generation. Specific to Databricks E2E use case. (comma-separated, required if ParameterResourceGroups is not specified)."
    Write-Host "  -DryRun                    Simulate deployment without making any changes. (default: false)"
    exit 1
}

# Validate required parameters
if (-not $SubscriptionId) {
    Log-Message "Missing required parameter: SubscriptionId" "ERROR"
    Show-Usage
}

# Validate the script path
if (-not (Test-Path -Path $ScriptPath)) {
    Log-Message "Script file not found at path: $ScriptPath" "ERROR"
    exit 1
}

# Authenticate and set subscription context
try {
    Log-Message "Authenticating with Azure..." "INFO"
    $Context = Get-AzContext
    if (-not $Context) {
        Connect-AzAccount -ErrorAction Stop
    }
    Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    Log-Message "Subscription context set to: $SubscriptionId" "INFO"
} catch {
    Log-Message "Authentication or subscription setup failed: $_" "ERROR"
    exit 1
}

# Create the Resource Group if it does not exist or recreate it if the location is incorrect
try {
    $existingResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $existingResourceGroup) {
        if (-not $DryRun) {
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
        }
        Log-Message "Resource Group '$ResourceGroupName' created in location '$Location'." "INFO"
    } elseif ($existingResourceGroup.Location -ne $Location) {
        if (-not $DryRun) {
            Remove-AzResourceGroup -Name $ResourceGroupName -Force -ErrorAction Stop
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
        }
        Log-Message "Resource Group '$ResourceGroupName' recreated in location '$Location'." "INFO"
    } else {
        Log-Message "Resource Group '$ResourceGroupName' already exists and is in the correct location." "INFO"
    }
} catch {
    Log-Message "Failed to create or update Resource Group: $_" "ERROR"
    exit 1
}

# Create or update the Automation Account
try {
    $existingAutomationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -ErrorAction SilentlyContinue
    if (-not $existingAutomationAccount) {
        if (-not $DryRun) {
            New-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -Location $Location -ErrorAction Stop
        }
        Log-Message "Automation Account '$AutomationAccountName' created in Resource Group '$ResourceGroupName'." "INFO"
    } elseif ($existingAutomationAccount.Location -ne $Location) {
        Log-Message "Automation Account '$AutomationAccountName' exists but in a different location ('$existingAutomationAccount.Location'). Please reconcile manually." "WARNING"
    } else {
        Log-Message "Automation Account '$AutomationAccountName' already exists and is up to date." "INFO"
    }
} catch {
    Log-Message "Failed to create or update Automation Account: $_" "ERROR"
    exit 1
}

# Enable or update Managed Identity for the Automation Account
try {
    $identity = (Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName).Identity
    if (-not $identity) {
        if (-not $DryRun) {
            Set-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -AssignSystemIdentity -ErrorAction Stop
        }
        Log-Message "Managed Identity enabled for Automation Account." "INFO"
    } else {
        Log-Message "Managed Identity already enabled for Automation Account." "INFO"
    }
} catch {
    Log-Message "Failed to enable or verify Managed Identity: $_" "ERROR"
    exit 1
}

# Assign Contributor Role to the Managed Identity if not already assigned
try {
    $identityPrincipalId = (Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName).Identity.PrincipalId
    $existingRoleAssignment = Get-AzRoleAssignment -ObjectId $identityPrincipalId -RoleDefinitionName "Contributor" -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue
    if (-not $existingRoleAssignment) {
        if (-not $DryRun) {
            New-AzRoleAssignment -ObjectId $identityPrincipalId -RoleDefinitionName "Contributor" -Scope "/subscriptions/$SubscriptionId" -ErrorAction Stop
        }
        Log-Message "Assigned 'Contributor' role to Managed Identity." "INFO"
    } else {
        Log-Message "'Contributor' role already assigned to Managed Identity." "INFO"
    }
} catch {
    Log-Message "Failed to assign Contributor role: $_" "ERROR"
    exit 1
}

# Import or update the script as a Runbook
try {
    $existingRunbook = Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -ErrorAction SilentlyContinue
    if (-not $existingRunbook) {
        if (-not $DryRun) {
            Import-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -Path $ScriptPath -Type PowerShell -ErrorAction Stop
            Publish-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -ErrorAction Stop
        }
        Log-Message "Runbook '$RunbookName' imported and published." "INFO"
    } else {
        if (-not $DryRun) {
            Remove-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -Force -ErrorAction Stop
            Import-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -Path $ScriptPath -Type PowerShell -ErrorAction Stop
            Publish-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -ErrorAction Stop
        }
        Log-Message "Runbook '$RunbookName' updated and republished." "INFO"
    }
} catch {
    Log-Message "Failed to import or update Runbook: $_" "ERROR"
    exit 1
}

# Create or update a schedule for the Runbook
try {
    $existingSchedule = Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ErrorAction SilentlyContinue
    if (-not $existingSchedule) {
        if (-not $DryRun) {
            switch ($ScheduleFrequency) {
                "Day" {
                    New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $ScheduleStartTime -DayInterval $ScheduleInterval -TimeZone "UTC" -ErrorAction Stop
                }
                "Week" {
                    New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $ScheduleStartTime -WeekInterval $ScheduleInterval -TimeZone "UTC" -ErrorAction Stop
                }
                "Month" {
                    New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $ScheduleStartTime -MonthInterval $ScheduleInterval -TimeZone "UTC" -ErrorAction Stop
                }
                "Hour" {
                    New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $ScheduleStartTime -HourInterval $ScheduleInterval -TimeZone "UTC" -ErrorAction Stop
                }
                default {
                    Log-Message "Unsupported ScheduleFrequency: $ScheduleFrequency" "ERROR"
                    exit 1
                }
            }
        }
        Log-Message "Schedule '$ScheduleName' created to start at $ScheduleStartTime." "INFO"
    } else {
        if (($existingSchedule.StartTime -ne $ScheduleStartTime) -or ($existingSchedule.Interval -ne $ScheduleInterval)) {
            if (-not $DryRun) {
                Remove-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -Force -ErrorAction Stop
                switch ($ScheduleFrequency) {
                    "Day" {
                        New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $ScheduleStartTime -DayInterval $ScheduleInterval -TimeZone "UTC" -ErrorAction Stop
                    }
                    "Week" {
                        New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $ScheduleStartTime -WeekInterval $ScheduleInterval -TimeZone "UTC" -ErrorAction Stop
                    }
                    "Month" {
                        New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $ScheduleStartTime -MonthInterval $ScheduleInterval -TimeZone "UTC" -ErrorAction Stop
                    }
                    "Hour" {
                        New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $ScheduleStartTime -HourInterval $ScheduleInterval -TimeZone "UTC" -ErrorAction Stop
                    }
                    default {
                        Log-Message "Unsupported ScheduleFrequency: $ScheduleFrequency" "ERROR"
                        exit 1
                    }
                }
            }
            Log-Message "Schedule '$ScheduleName' updated to match new settings." "INFO"
        } else {
            Log-Message "Schedule '$ScheduleName' is up to date." "INFO"
        }
    }

    $parameters = @{
        SubscriptionId = $SubscriptionId
        ResourceGroups = $ParameterResourceGroups
        Action = $ParameterAction
        Environments = $ParameterEnvironments
        Project = $ParameterProject
        DeploymentIds = $ParameterDeploymentIds
    }

    if ($DryRun) {
        $parameters["DryRun"] = $true
    }

    if ($InstallModules) {
        $parameters["InstallModules"] = $true
    }

    $existingScheduleLink = Get-AzAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -RunbookName $RunbookName -ScheduleName $ScheduleName -ErrorAction SilentlyContinue
    if (-not $existingScheduleLink) {
        if (-not $DryRun) {
            Register-AzAutomationScheduledRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -RunbookName $RunbookName -ScheduleName $ScheduleName -Parameters $parameters -ErrorAction Stop
        }
        Log-Message "Schedule '$ScheduleName' linked to Runbook '$RunbookName'." "INFO"
    } else {
        Log-Message "Schedule '$ScheduleName' is already linked to Runbook '$RunbookName'." "INFO"
    }
} catch {
    Log-Message "Failed to create, update, or link schedule: $_" "ERROR"
    exit 1
}

# Final error and warning summary
Log-Message "Script completed with $global:iErrorCount error(s) and $global:iWarningCount warning(s)." "INFO"
