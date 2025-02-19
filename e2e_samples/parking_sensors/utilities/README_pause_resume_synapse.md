# Pause/Resume Azure Synapse SQL Pools and Azure SQL Data Warehouse Script

## Overview

This PowerShell script is designed to automate the pausing or resuming of Azure Synapse SQL Pools and Azure SQL Data Warehouse (Dedicated SQL Pools). This functionality helps organizations optimize costs by pausing unused resources and resuming them when needed.

It supports both manual execution and deployment as an Azure Automation Runbook with a Managed Identity, making it ideal for scheduled automation tasks.

---

## Features

- **Automated Pause/Resume**:
  - Dynamically pause or resume SQL Pools across specific or all resource groups.
- **Flexible Execution**:
  - Run locally with PowerShell or automate through Azure Automation.
- **Custom Parameters**:
  - Specify environments (e.g., dev, stg, prod) and projects for targeted execution.
- **Error and Warning Tracking**:
  - Logs all errors and warnings, providing a detailed summary at the end.
- **Dry Run Mode**:
  - Simulate actions without making changes to validate configurations.

---

## Parameters

| Parameter        | Description                                                                                             | Default   | Example                                      |
|------------------|---------------------------------------------------------------------------------------------------------|-----------|----------------------------------------------|
| `SubscriptionId` | Azure Subscription ID. Required for local execution.                                                   |           | `12345678-1234-1234-1234-123456789abc`       |
| `DeploymentIds`  | Comma-separated deployment IDs. Required if `ResourceGroups` is not provided. Specific to Databricks E2E use case. |           | `tst01, tst02`                    |
| `Project`        | Project name. Required if `ResourceGroups` is not provided. Specific to Databricks E2E use case.        |           | `mdwdops`                                   |
| `Environments`   | Environments (e.g., dev, stg, prod).                                                                   | `dev,stg` | `dev,stg,prod`                               |
| `ResourceGroups` | Comma-separated list of resource groups. Use `*` to target all resource groups in the subscription.    |           | `mdwdops-tst01-dev-rg,mdwdops-tst01-stg-rg`              |
| `Action`         | Specify `Pause` or `Resume`.                                                                           | `Pause`   | `Pause`                                      |
| `DryRun`         | Simulate actions without making changes.                                                               | `false`   | `false`                                       |
| `InstallModules` | Install missing modules if not present.                                                                | `false`   | `true`                                       |

---

## Example Scenarios

### 1. Pause All SQL Pools in a Subscription
```powershell
.\pause_resume_synapse.ps1 -SubscriptionId "SubscriptionId" -ResourceGroups "*" -Action "Pause"
```

### 2. Resume SQL Pools for a Specific Project in Dev, Stg and Prod Environments
```powershell
.\pause_resume_synapse.ps1 -SubscriptionId "SubscriptionId" -Project "Project1" -DeploymentIds "Deployment1,Deployment2" -Environments "dev,stg,prod" -Action "Resume"
```

### 3. Test Without Making Changes
```powershell
.\pause_resume_synapse.ps1 -SubscriptionId "SubscriptionId" -ResourceGroups "*" -Action "Pause" -DryRun
```

---

## Prerequisites

1. **Azure Subscription**: Ensure you have access to an Azure subscription.
2. **Azure PowerShell Module**: Ensure `Az.Accounts`, `Az.Sql`, `Az.Synapse`, `Az.Automation`, and `Az.Resources` modules are installed. Alternatively, use the `-InstallModules` parameter to install missing modules automatically.
3. **Required Azure Roles**:
   - Assign the `Contributor` role to the Automation Account's managed identity for the scope `/subscriptions/<subscriptionid>`.
   - Optionally, assign more restrictive permissions as needed (e.g., for specific Resource Groups).
4. **PowerShell Environment**: If running locally, ensure the account has appropriate permissions.

---

## Local Execution

To execute the script manually:

1. Download the script (`pause_resume_synapse.ps1`) to your local machine.
2. Open PowerShell and navigate to the script's location.
3. Run the script with the desired parameters. Example:

    ```powershell
    .\pause_resume_synapse.ps1 -SubscriptionId "<SubscriptionId>" -ResourceGroups "<ResourceGroup1,ResourceGroup2>" -Action "Pause"
    ```
4. Review the output for warnings, errors, or success messages.

---

## Azure Automation Deployment
### 1. Create a Resource Group for Automation
To keep resources organized, create a dedicated Resource Group for the Automation Account:

*Using Bash*
```bash
az group create --name "Automation-RG" --location "East US"
```

*Using PowerShell*
```powershell
New-AzResourceGroup -Name "Automation-RG" -Location "East US"
```

### 2. Create an Azure Automation Account

*Using Bash*
```bash
az automation account create --resource-group "Automation-RG" --name "SynapseAutomation" --location "East US"
```

*Using PowerShell*
```powershell
New-AzAutomationAccount -ResourceGroupName "Automation-RG" -Name "SynapseAutomation" -Location "East US"
```

### 3. Enable System-Assigned Managed Identity

*Using Bash*
```bash
az resource update --resource-group "Automation-RG" --name "SynapseAutomation" --resource-type "Microsoft.Automation/automationAccounts" --set identity.type=SystemAssigned
```

*Using PowerShell*
```powershell
Set-AzAutomationAccount -ResourceGroupName "Automation-RG" -Name "SynapseAutomation" -AssignSystemIdentity
```

### 4. Retrieve the Object ID of the Managed Identity

*Using Bash*
```bash
az resource show --resource-group "Automation-RG" --name "SynapseAutomation" --resource-type "Microsoft.Automation/automationAccounts" --query "identity.principalId" --output tsv
```

*Using PowerShell*
```powershell
(Get-AzAutomationAccount -ResourceGroupName "Automation-RG" -Name "SynapseAutomation").Identity.PrincipalId
```

### 5. Assign Managed Identity Permissions
Grant the Managed Identity appropriate permissions:

*Using Bash*
```bash
az role assignment create --assignee-object-id "<ManagedIdentityObjectId>" --role "Contributor" --scope "/subscriptions/<subscription-id>" --assignee-principal-type "ServicePrincipal"
```

*Using PowerShell*
```powershell
New-AzRoleAssignment -ObjectId "<ManagedIdentityObjectId>" -RoleDefinitionName "Contributor" -Scope "/subscriptions/<subscription-id>"
```

Replace "subscription-id" with your Azure subscription ID and "ManagedIdentityObjectId" with the output of the previous command.

### 6. Import the Script into the Automation Account
This can be done directly in Azure Portal using the following steps:
1. In the Azure Portal, go to your Automation Account.
2. Navigate to Runbooks > Add a Runbook.
3. Upload the script and set its type to PowerShell.

For a fully automated solution, follow these commands:

1. Create the Runbook and Upload the script

    *Using Bash*
    ```bash
    az automation runbook create --resource-group "Automation-RG" --automation-account-name "SynapseAutomation" --name "PauseResumeSynapse" --type "PowerShell"

    az automation runbook replace-content --resource-group "Automation-RG" --automation-account-name "SynapseAutomation" --name "PauseResumeSynapse" --content @"./pause_resume_synapse.ps1"
    ```

    *Using PowerShell*
    ```powershell
    Import-AzAutomationRunbook -ResourceGroupName "Automation-RG" -AutomationAccountName "SynapseAutomation" -Name "PauseResumeSynapse" -Path "./pause_resume_synapse.ps1" -Type PowerShell
    ```

2. Publish the Runbook

    *Using Bash*
    ```bash
    az automation runbook publish --resource-group "Automation-RG" --automation-account-name "SynapseAutomation" --name "PauseResumeSynapse"
    ```

    *Using PowerShell*
    ```powershell
    Publish-AzAutomationRunbook -ResourceGroupName "Automation-RG" -AutomationAccountName "SynapseAutomation" -Name "PauseResumeSynapse"
    ```

### 7. Test the Runbook
1. Go to the Runbooks section of your Automation Account.
2. Select your uploaded Runbook.
3. Click Start and provide the necessary parameters.

---

## Scheduling Automation

To schedule the script in Azure Automation using Azure Portal:
1. Navigate to the Runbooks section of your Automation Account.
2. Select your Runbook.
3. Click Link to schedule.
4. Create a new schedule and configure it (e.g., daily at midnight).

To schedule the Runbook using Commands:
1. Create a schedule in the Automation Account:

*Using Bash*
```bash
# Calculate midnight for the next day in UTC -- or set manually to a specific time such as "2025-01-24T00:00:00Z"
$startTime = (Get-Date).AddDays(1).Date.ToUniversalTime()

az automation schedule create --resource-group "Automation-RG" --automation-account-name "SynapseAutomation" --name "DailyPause" --start-time $startTime --time-zone UTC --frequency "Day" --interval 1
```

*Using PowerShell*
```powershell
# Calculate midnight for the next day in UTC -- or set manually to a specific time such as "2025-01-24T00:00:00Z"
$startTime = (Get-Date).AddDays(1).Date.ToUniversalTime() 

New-AzAutomationSchedule `
    -ResourceGroupName "Automation-RG" `
    -AutomationAccountName "SynapseAutomation" `
    -Name "DailyPause" `
    -StartTime $startTime `
    -DayInterval 1 `
    -TimeZone "UTC"
```

2. Link the schedule to the Runbook:
   After reviewing the [Azure CLI commands for Azure Automation](https://learn.microsoft.com/en-us/cli/azure/automation?view=azure-cli-latest), there is no direct Azure CLI command to link a schedule to a runbook. The ability to link a schedule to a runbook can only be done via the Azure Portal, PowerShell, or using the Azure REST API.

*Using PowerShell*
```powershell
Register-AzAutomationScheduledRunbook `
    -AutomationAccountName "SynapseAutomation" `
    -ResourceGroupName "Automation-RG" `
    -RunbookName "PauseResumeSynapse" `
    -ScheduleName "DailyPause" `

    # Add any relevant parameter based on your need
    -Parameters @{
        #SubscriptionId = "SubscriptionId"
        #DeploymentIds  = "Deployment1,Deployment2"
        #project        = "ProjectName"
        #Environments   = "dev,stg,prod"
        #ResourceGroups = "*"
        #Action         = "Pause"
    }
```

---

## Logging and Monitoring

1. **Error Logging**:
   - Navigate to your Automation Account in the Azure Portal.
   - Go to Jobs to view the status of Runbook executions.
   - Check the logs for warnings, errors, or success messages.
2. **Error and Warning Counters**:
   - The script tracks errors and warnings globally.
   - The final log will show the total number of errors and warnings encountered.
3. **Dry Run**:
   - Use the -DryRun flag to simulate actions without making any changes.

---

## Troubleshooting

- **Module Errors**: Ensure Azure modules are installed and updated: `Update-Module -Name Az -Force`.
- **Permission Issues**: Verify the Managed Identity has appropriate role assignments. Ensure local accounts have sufficient permissions.
- **Azure Automation Errors**: Review the Runbook job logs for detailed error messages.

---

## Notes

- **Dry Run Mode**: Use the `-DryRun` switch to verify actions before making changes.
- **Error and Warning Summary**: At the end of the script, a summary of errors and warnings is displayed.

---

## References

- [Pause and resume compute in dedicated SQL pool (formerly SQL DW) with Azure PowerShell](https://learn.microsoft.com/azure/synapse-analytics/sql-data-warehouse/pause-and-resume-compute-powershell)
- [Pause and Resume Compute in Synapse Workspace with PowerShell](https://learn.microsoft.com/azure/synapse-analytics/sql-data-warehouse/pause-and-resume-compute-workspace-powershell)
- [Azure Automation Overview](https://learn.microsoft.com/azure/automation/automation-intro)
- [Azure Automation Runbooks](https://learn.microsoft.com/azure/automation/automation-runbook-types)
- [Manage schedules in Azure Automation](https://learn.microsoft.com/azure/automation/shared-resources/schedules)
- [Using a system-assigned managed identity for an Azure Automation account](https://learn.microsoft.com/azure/automation/enable-managed-identity-for-automation)
- [Azure PowerShell Documentation](https://learn.microsoft.com/powershell/azure/new-azureps-module-az)
- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
- [Azure CLI Automation Commands](https://learn.microsoft.com/cli/azure/automation?view=azure-cli-latest)
- [Resume-AzSynapseSqlPool PowerShell Command](https://github.com/Azure/azure-powershell/blob/main/src/Synapse/Synapse/help/Resume-AzSynapseSqlPool.md)
- [Suspend-AzSynapseSqlPool PowerShell Command](https://github.com/Azure/azure-powershell/blob/main/src/Synapse/Synapse/help/Suspend-AzSynapseSqlPool.md)
- [Azure PowerShell GitHub Repository](https://github.com/Azure/azure-powershell/tree/main)
- [AZ.Automation PowerShell Commands](https://learn.microsoft.com/powershell/module/az.automation)
- [Azure Automation Pricing](https://azure.microsoft.com/pricing/details/automation/)

---

## License

This script is provided "as-is" without warranty of any kind. Use at your own risk.

---

This Readme file provides a complete overview of how to use the script, deploy it to Azure Automation, set up permissions, and troubleshoot common issues.

