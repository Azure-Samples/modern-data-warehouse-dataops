# DataOps - Synapse Integration Testing <!-- omit in toc -->

This sample showcases additional integration tests for Azure Synapse. It includes the deployment of infrastructure based on the E2E sample [DataOps - Parking Sensor (Synapse)](https://github.com/Azure-Samples/modern-data-warehouse-dataops/tree/main/e2e_samples/parking_sensors_synapse).

## Contents <!-- omit in toc -->

- [Solution Overview](#solution-overview)
  - [Technologies used](#technologies-used)
- [Key Concepts](#key-concepts)
  - [Environments](#environments)
  - [Testing](#testing)
- [How to use the sample](#how-to-use-the-sample)
  - [Prerequisites](#prerequisites)
    - [Software pre-requisites if you use dev container](#software-pre-requisites-if-you-use-dev-container)
  - [Setup and Deployment](#setup-and-deployment)
    - [Deployed Resources](#deployed-resources)
    - [Integration Tests](#integration-tests)
    - [Clean up](#clean-up)
  - [Data Lake Physical layout](#data-lake-physical-layout)

---------------------

## Solution Overview

The solution runs a flow triggered on a storage file upload. It then runs a sample ETL process in a [Notebook](https://learn.microsoft.com/en-us/azure/synapse-analytics/spark/apache-spark-development-using-notebooks). Once completed, the data is loaded into [Azure Synapse - SQL Dedicated Pool (formerly SQLDW)](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-overview-what-is?context=/azure/synapse-analytics/context/context). The entire pipeline is orchestrated with [Azure Synapse Data Pipelines](https://docs.microsoft.com/en-us/azure/data-factory/concepts-pipelines-activities?context=/azure/synapse-analytics/context/context&tabs=synapse-analytics).

### Technologies used

It makes use of the following azure services:

- [Azure Synapse Analytics](https://azure.microsoft.com/en-au/services/synapse-analytics/)
- [Azure Data Lake Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)

## Key Concepts

### Environments

1. **Sandbox and Dev**- the DEV resource group is used by developers to build and test their solutions. It contains two logical environments - (1) a Sandbox environment per developer so each developer can make and test their changes in isolation prior committing to `main`, and (2) a shared Dev environment for integrating changes from the entire development team. "Isolated" sandbox environment are accomplish through a number of practices depending on the Azure Service.
   - DataLake Gen2 - a "sandbox" file system is created. Each developer creates their own folder within this Sandbox filesystem.
   - AzureSQL or SQLDW - A transient database (restored from DEV) is spun up per developer on demand, if required.
   - Azure Synapse - git integration allows them to make changes to their own branches and debug runs independently.

### Testing

- Integration Testing - These can be ran manually to ensure integration points of the solution function as expected. In this demo solution, an actual Synapse Data Pipeline run is automatically triggered and its output verified.
  - See here for the [integration tests](./tests/integrationtests/).

## How to use the sample

### Prerequisites

1. [Azure Account](https://azure.microsoft.com/en-au/free/search/?&ef_id=Cj0KCQiAr8bwBRD4ARIsAHa4YyLdFKh7JC0jhbxhwPeNa8tmnhXciOHcYsgPfNB7DEFFGpNLTjdTPbwaAh8bEALw_wcB:G:s&OCID=AID2000051_SEM_O2ShDlJP&MarinID=O2ShDlJP_332092752199_azure%20account_e_c__63148277493_aud-390212648371:kwd-295861291340&lnkd=Google_Azure_Brand&dclid=CKjVuKOP7uYCFVapaAoddSkKcA)
   - *Permissions needed*: ability to create and deploy to an Azure [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview), a [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals), and grant the [Contributor role](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) to the service principal over the resource group.

#### Software pre-requisites if you don't use dev container<!-- omit in toc -->

- For Windows users, [Windows Subsystem For Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
- [az cli 2.43+](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Azure DevOps CLI](https://marketplace.visualstudio.com/items?itemName=ms-vsts.cli)
  - To install, run `az extension add --name azure-devops`
- [Python 3+](https://www.python.org/)
- [jq](https://stedolan.github.io/jq/)
- [makepasswd](https://manpages.debian.org/stretch/makepasswd/makepasswd.1.en.html)

#### Software pre-requisites if you use dev container

- [Docker](https://www.docker.com/)
- [VSCode](https://code.visualstudio.com/)
- [Visual Studio Code Remote Development Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

  The Dev Container will automatically install all required technologies. It is strongly recommended to use dev container for the deployment to avoid environment related issues.

### Setup and Deployment

> **IMPORTANT NOTE:** As with all Azure Deployments, this will **incur associated costs**. Remember to teardown all related resources after use to avoid unnecessary costs. See [here](#deployed-resources) for list of deployed resources. See [here](#clean-up) for information on the clean_up script.
> This deployment was tested using WSL 2 (Ubuntu 20.04) and Debian GNU/Linux 9.9 (stretch)

1. **Environment Setup**
   - Open the project folder in VS Code.
   - Rename the file `.envtemplate` under ".devcontainer" folder to `devcontainer.env` and update the values as mentioned below.
   - Open the project in the Dev Container (see details [here](docs/devcontainer.md)).
   - **Alternatively**. You can export the environment variables in the bash terminal after opening the Dev Container or if not using a Dev Contaienr. For example: `export DEPLOYMENT_ID="xxxxx"`.

    -Set the following environment variables:
      - **AZURE_LOCATION** - Azure location to deploy resources. *Default*: default azure location.
        > Note: You can see all available locations (after setting the Azure cloud shown in the following step if required) with the bash command `az account list-locations --query [].name --output tsv`.
      - **AZURE_SUBSCRIPTION_ID** - Azure subscription id to use to deploy resources. *Default*: default azure subscription. To see your default, run `az account list`.
      - **DEPLOYMENT_ID** - string appended to all resource names. This is to ensure uniqueness of azure resource names. *Default*: random five character string.
      - **SYNAPSE_SQL_PASSWORD** - Password of the Synapse SQL instance. *Default*: random string.

2. **Initial Setup**
   - Ensure that:
      - You have the desired Azure Cloud set. To change from the default (`AzureCloud`), run

        ```bash
        az cloud set -n <AZURE_CLOUD_NAME>
        ```

          - For example, if you want to use the Azure US Gov cloud, run

            ```bash
            az cloud set -n AzureUSGovernment
            ```

          - To see all of the Azure Cloud options, run

            ```bash
            az cloud list --output table
            ```

      - You are logged in to the Azure CLI. To login, run

        ```bash
        az login
        ```

      - Azure CLI is targeting the Azure Subscription you want to deploy the resources to. To set target Azure Subscription, run

        ```bash
        az account set -s <AZURE_SUBSCRIPTION_ID>
        ```

3. **Deploy Azure resources**
   - Run `./deploy.sh`.
      - After a successful deployment, you will find `.env.dev` files containing essential configuration information per environment. See [here](#deployed-resources) for list of deployed resources.
      - Note that if you are using **dev container**, you would run the same script but inside the dev container terminal.

4. **Trigger the Synapse Pipeline**

   - This solution starts the Trigger as part of deployment. You can turn the trigger on or off by opening the **DEV** Synapse workspace, navigating to "Manage > Triggers", then select the `T_Stor` trigger and activate/deactive it by clicking on the "Play"/"Pause" icon next to it. Click `Publish` to publish changes.
   - **Optional**. Trigger the Synapse Data Pipelines in the dev environment.
      - In the Synapse workspace of the dev environment, navigate to "Integrate", then select the pipeline.
      - Select "Trigger > Trigger Now".
      - Enter the name of a file in the storage account in the `datalake` container (upload this file before starting the trigger).
      - To monitor the run, go to "Monitor > Pipeline runs".
      ![Pipeline Run](docs/images/SynapseRun.png?raw=true "Pipeline Run]")
   - If a redeployment is required of the Trigger and it has been activated, it will need to be manually deactivated before redeployment will be successful.

Congratulations!! 🥳 You have successfully deployed the solution.

If you are stuck, please file a Github issue with the relevant error message, error screenshots, and replication steps.

#### Deployed Resources

After a successful deployment, you should have the following resources:

- In Azure, **one Resource Group** with the following Azure resources.
  - **Azure Synapse Workspace** including:
    - **Data Pipelines** - with pipelines, datasets, linked services, triggers deployed and configured correctly.
    - **Notebooks** - Spark, SQL Serverless
    - **Spark Pool**
    - **SQL Dedicated Pool (formerly SQLDW)** - Initally empty. Synapse Pipeline will create a table and content.
    - Note: The Synapse workspace deploys with a firewall rule granting access to all IP addresses.
  - **Data Lake Store Gen2** and a **Service Principal (SP)** with Storage Contributor rights assigned.
  - **KeyVault** with relevant secrets stored.
- Locally, a file `dev.env` that contains the environment variables and values needed for the integration test suite. Please take care of this file as it contains secrets.

#### Integration Tests

- Feel free to jump to the [Integration Tests](./tests/integrationtests/README.md) suite section to test the solution in your Azure environment!

> Note: Friendly suggestion: open that section in a new window in VS Code and keep this one open so you can easily copy/paste the environment variables and come back to run the clean up script.

#### Clean up

This sample comes with an [optional, interactive clean-up script](./scripts/clean_up.sh) which will delete resources with `mdwdops` in its name. It will list resources to be deleted and will prompt before continuing.
> IMPORTANT NOTE: As it simply searches for `mdwdops` in the resource name, it could list resources not part of the deployment! Use with care.

### Data Lake Physical layout

ADLS Gen2 is structured as the following:

```text
    datalake                    <- filesystem
    saveddata                   <- filesystem
```
