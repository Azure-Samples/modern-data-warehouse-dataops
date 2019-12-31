# Azure SQL Database

**WIP**

## Prerequisites

## Setup

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

#### Github Actions Pipelines
TODO

### Testing

### Observability / Monitoring
