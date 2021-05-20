# Provision an Azure Databricks Environment using Azure Devops Pipeline

This sample demonstrates how to provision an Azure Databricks environment using an Azure Devops pipeline. This sample leverages [sample1_basic_azure_databricks_environment](../../sample1_basic_azure_databricks_environment/README.md) and [sample3_cluster_provisioning_and_data_access](../../sample3_cluster_provisioning_and_data_access/README.md) for ARM templates and shell scripts to create the services.

An [Azure Devops pipeline](iac-create-environment-pipeline-arm.yml) is used to orchestrate the provisioning of environment. The pipeline includes three stages, one for each deployment environment (DEV, STG, PROD). It is triggered manually with the option to deploy to one or more environments. A common [job template](../templates/jobs/deploy-azure-databricks-environment.yml) is used in conjunction with three different variable groups and service connections, one for each deployment environment.

The following services are provisioned as a part of this setup:

   1. Azure Databricks Workspace
   2. Azure Databricks Clusters - a basic cluster and a high concurrency cluster
   3. Azure Storage account with hierarchical namespace enabled to support ABFS
   4. Azure key vault to store secrets and access tokens

## How to use this sample

### Prerequisites

- [Github account](https://github.com/)
- [Azure DevOps account](https://azure.microsoft.com/en-au/services/devops/)
- [A service connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/github?view=azure-devops&tabs=yaml#oauth-authentication) to grant Azure Devops Pipelines access to the YAML file in GitHub repository.

### Setup and deployment

1. Clone this repository.
1. In Azure DevOps, define three [Variable Groups](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml) with the naming convention `mdwdo-dbx-release-<environment>` (where `<environment>` stands for `dev`, `stg`, `prod`) with the following variables:
    1. **AZURE_RESOURCE_GROUP_LOCATION** - Azure region where the resources will be deployed. (e.g. australiaeast, eastus, etc.).
    1. **AZURE_RESOURCE_GROUP_NAME** - Name of the containing resource group.
    1. **AZURE_SUBSCRIPTION_ID** - Subscription ID of the Azure subscription where the resources will be deployed.
    1. **DEPLOYMENT_PREFIX** - Prefix for the resource names which will be created as a part of this deployment.
    > Note:
    - DEPLOYMENT_PREFIX can contain numbers and lowercase letters only. This is to keep in line with the naming standards allowed for Azure Storage Account.
    - The variable names in variable groups have been constructed in a manner that allows them to be injected into pipeline tasks as [environment variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#environment-variables). For example, on UNIX systems (macOS and Linux), environment variables have the format `$VARIABLE_NAME`.
1. In Azure DevOps, [create three Azure Resource Manager service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops) with the naming convention `mdwdo-dbx-serviceconnection-<environment>` (where `<environment>` stands for `dev`, `stg`, `prod`).
1. In Azure DevOps, [create a pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline?view=azure-devops&tabs=java%2Ctfs-2018-2%2Cbrowser) using [iac-create-environment-pipeline-arm.yml](iac-create-environment-pipeline-arm.yml) file.
1. Choose one or more stages for deployment and run the pipeline manually.