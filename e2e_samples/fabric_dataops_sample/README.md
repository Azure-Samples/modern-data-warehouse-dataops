# Microsoft Fabric DataOps Sample

Microsoft Fabric is an end-to-end analytics and data platform designed for enterprises that require a unified solution. It encompasses data movement, processing, ingestion, transformation, real-time event routing, and report building. Operating on a Software as a Service (SaaS) model, Fabric brings simplicity and integration to data and analytics solutions.

This simplification comes at a cost, however. The SaaS nature of Fabric makes the DataOps process more complex. Customer needs to learn new ways of deploying, testing, and handling workspace artifacts. The CI/CD process for Fabric workspaces also differs from traditional CI/CD pipelines. For example, using Fabric deployment pipelines for promoting artifacts across environments is a unique feature of Fabric, and doesn't have a direct equivalent in other CI/CD tools.

This sample aims to provide customers a reference end-to-end (E2E) implementation of DataOps on Microsoft Fabric.

## Overview

While Fabric is an end-to-end platform, it works best when integrated with other Azure services such as Application Insights, Azure Key Vault, ADLS Gen2, Microsoft Purview and so. This dependency is also because customers have existing investments in these services and want to leverage them with Fabric.

## Infrastructure Setup

The infrastructure setup for this sample is broadly divided into two parts:

### Azure Resources

The Azure resources are deployed using Terraform. The sample uses the local backend for storing the Terraform state, but it can be easily modified to use remote backends. The following resources are deployed:

- Azure Data Lake Storage Gen2 (ADLS Gen2)
- Azure Key Vault
- Azure Log Analytics Workspace
- Azure Application Insights
- Fabric Capacity

### Fabric Resources

The Fabric resources are deployed using the Fabric REST APIs. Once the terraform provider for Fabric is available, the sample would be updated to use that. The following resources are deployed:

- Microsoft Fabric Workspace
- Microsoft Fabric Lakehouse
- Azure Data Lake Storage Gen2 shortcut
- Microsoft Fabric Environment
- Microsoft Fabric Notebooks
- Microsoft Fabric Data pipelines

### Prerequisites

- An Azure subscription.
- A user account with elevated privileges:
  - Ability to create service principals and Entra security groups.
  - Ability to create and manage Azure resources including Fabric capacity.
  - "Fabric Administrator" role.
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) and [jq](https://jqlang.github.io/jq/download/)
- Access to Azure DevOps organization and project.
- An Azure Repo.

### Setting up the Infrastructure

1. Clone the repository:

    ```bash
    # Optional
    az login --tenant "<tenant_id>"
    az account set -s "<subscription_id>"
    cd "<installation_folder>"
    # Repo clone
    git clone https://github.com/Azure-Samples/modern-data-warehouse-dataops.git
    ```

1. Change the directory to the `infra` folder of the sample:

    ```bash
    cd ./modern-data-warehouse-dataops/e2e_samples/fabric_dataops_sample/infra
    ```

1. Rename the [.envtemplate](./.envtemplate) file to `.env` and fill in the necessary environment variables. Here is the detailed explanation of the environment variables:

    ```bash
    BASE_NAME="The base name of the Fabric project. This name is used for naming the Azure and Fabric resources."
    LOCATION="The location of the Azure resources. This location is used for creating the Azure resources."
    ALDS_GEN2_CONNECTION_ID="The connection ID for the ADLS Gen2 'Cloud Connection'. If not provided, the ALDS Gen2 shortcut creation would be skipped."
    ```

Leave `ALDS_GEN2_CONNECTION_ID` blank for the first run.

1 . Review [setup-infra.sh](./infra/setup-infra.sh) script and see if you want to adjust the derived naming of variable names of Azure/Fabric resources.

1. The Azure resources are created using Terraform. The naming of the Azure resources is derived from the `BASE_NAME` environment variable. Please review the [main.tf](./infra/terraform/main.tf) file to understand the naming convention, and adjust it as needed.

1. Run the [setup-infra.sh](./infra/setup-infra.sh) script:

    ```bash
    ./setup-infra.sh
    ```

    The script is designed to be idempotent. Running the script multiple times will not result in duplicate resources. Instead, it will either skip or update existing resources. However, it is recommended to review the script, the output logs, and the created resources to ensure everything is as expected.

    Also, note that the bash script calls a python script [setup_fabric_environment.py](./infra/scripts/setup_fabric_environment.py) to upload custom libraries to the Fabric environment.

1. Once the deployment is complete, login to Fabric UI and create the cloud connection to ADLS Gen2 based on the [documentation](https://learn.microsoft.com/en-us/fabric/data-factory/connector-azure-data-lake-storage-gen2#set-up-your-connection-in-a-data-pipeline). Note down the connection id.

    ![fetching-connection-id](./images/cloud-connection.png)

1. Update variable `ALDS_GEN2_CONNECTION_ID` in `.env` file with the connection id fetched above and rerun the [setup-infra.sh](./infra/setup-infra.sh) script. This time, it would create the Lakehouse shortcut to ALDS Gen2 storage account. Rest of the resources would remain unchanged.

## Understanding the CI Process

## Running the Sample

## Cleaning up

## Known Issues, Limitations, and Workarounds

## References

- [Single-tech Sample - Fabric DataOps](./../../single_tech_samples/fabric/fabric_ci_cd/README.md)
- [Single-tech Sample - Multi-git Fabric DataOps](./../../single_tech_samples/fabric/fabric_cicd_gitlab/README.md)
- [E2E Sample - MDW Parking Sensors](./../parking_sensors/README.md)
