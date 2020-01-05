# Azure SQL Database

**WIP**

## Prerequisites

1. Github account.
2. Azure Account.
3. Azure DevOps Account.

### Software Prerequisites

1. [Azure CLI 2.0.49+](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
2. [Azure DevOps CLI](https://marketplace.visualstudio.com/items?itemName=ms-vsts.cli)
3. 
## Setup

1. Ensure the following:
   1. You are logged in to the az cli. To login, run `az login`
   2. Az CLI is targeting the Azure Subscription you want to deploy the resources to. To set target Azure Subscription, run `az account set -s <AZURE_SUBSCRIPTION_ID>`
   3. Az CLI is targeting the Azure DevOps organization and project you want to deploy the pipelines to. To set target Azure DevOps project, run `az devops configure --defaults organization=https://dev.azure.com/MY_ORG/ project=MY_PROJECT`
2. Fork this repository.
3. Clone the forked repository and cd in to `single_tech_samples/azuresql`.
4. Set the following environment variables:
   1. **RG_NAME** - target resource group to deploy to
   2. **RG_LOCATION** - location of target resource group
   3. **GITHUB_REPO_URL** - URL of your forked github repo
   4. **GITHUB_PAT_TOKEN** - a Github PAT token. Generate them [here](https://github.com/settings/tokens). This requires "repo" scope.
   5. **AZURESQL_SRVR_PASSWORD** - Password of the admin account for your AzureSQL server instance. Default usernamen: sqlAdmin.
5. Run `./deploy.sh`.


## Running the sample

## Key concepts

### Build and Release (CI/CD)

#### Azure DevOps Pipelines

The following are some sample [Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/?view=azure-devops) pipelines.

1. **Validate Pull Request** [[azure-pipelines-validate-pr](pipelines/azure-pipelines-validate-pr.yml)]
   - This pipeline builds the DACPAC and runs tests (if any). This is triggered only on PRs and is used to validate them before merging into master. This pipeline does not produce any artifacts.
2. **Build Pipeline** [[azure-pipelines-build](pipelines/azure-pipelines-build.yml)] 
   - This pipeline builds the DACPAC and publishes it as a [Build Artifact](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/build-artifacts?view=azure-devops&tabs=yaml). Its purpose is to produce the Build Artifact that may be consumed by a [Release Pipeline (classic)](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/?view=azure-devops). 
3. **Simple Multi-Stage Pipeline** [[azure-pipelines-simple-multi-stage](pipelines/azure-pipelines-simple-multi-stage.yml)]
   - This pipeline demonstrates a simple [multi-stage pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/multi-stage-pipelines-experience?view=azure-devops). 
   - It has two stages:
        1. Build - builds the DACPAC and creates a [Pipeline Artifact](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/pipeline-artifacts?view=azure-devops&tabs=yaml).
        2. Deploy - deploys the DACPAC to a target AzureSQL instance.
   - Required Pipeline Variables:
     - **AZURE_SERVICE_CONNECTION_NAME** - Name of the Azure Service Connection in Azure DevOps. The service connection needs to be authorized to deploy resources.
     - **AZURESQL_SERVER_NAME** - Name of the AzureSQL server (ei. myserver.database.windows.net)
     - **AZURESQL_DB_NAME** - Name of the AzureSQL Database
     - **AZURESQL_SERVER_USERNAME** - Username of AzureSQL login
     - **AZURESQL_SERVER_PASSWORD** - Password of AzureSQL login

#### Github Actions Pipelines
TODO

### Testing

### Observability / Monitoring
