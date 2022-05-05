# Pipelines and scripts

## Pipelines

### Main pipelines

The main pipelines are YAML files located in `/pipelines/` folder.

| Name | Purpose |
|------|---------|
| [Create infrastructure](../pipelines/create-infrastructure.yml) | Creates the complete base infrastructure. Executes the subset of jobs in `/pipelines/jobs/` folder. |

### Jobs

The jobs are located in `/pipelines/jobs/` folder.

| Name | Purpose |
| ---- | ------- |
| [Base infrastructure deployment job](../pipelines/jobs/create-infrastructure-job.yml) | Creates the base infrastructure. Utilizes the pipeline templates in `/pipelines/templates/` folder. |
| [Create Data Lake log sender job](../pipelines/jobs/create-data-lake-log-sender-job.yml) | Creates the Azure Function that sends the Azure Data Lake logs to Log Analytics. |
| [Create email sender (Logic App) job](../pipelines/jobs/create-email-sender-job.yml) | Creates a Logic App for sending emails. Used by Data Factory. |

### Variables

Pipeline variables for different environments - development, test and production - are located in `/pipelines/variables/` folder.

## PowerShell scripts

| Path/script | Description |
|-------------|-------------|
| [`/scripts/agent/Set-AgentTools.ps1`](../scripts/agent/Set-AgentTools.ps1) | Sets up the tools required by the build agent. |
| [`/scripts/environment/New-EnvironmentVariables.ps1`](../scripts/environment/New-EnvironmentVariables.ps1) | Sets environment variables required by the infrastructure pipelines. |
| [`/scripts/environment/Databricks-Post-Deploy.ps1`](../scripts/environment/Databricks-Post-Deploy.ps1) | Sets databricks workspace after it was provisioned. |
