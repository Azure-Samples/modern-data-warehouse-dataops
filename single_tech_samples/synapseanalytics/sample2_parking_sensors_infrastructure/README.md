# DataOps - Parking Sensor (Synapse) <!-- omit in toc -->

The sample demonstrate how DevOps principles can be applied to an end to end Data Pipeline Solution built according to the [Modern Data Warehouse (MDW)](https://azure.microsoft.com/en-au/solutions/architecture/modern-data-warehouse/) pattern, implemented in Azure Synapse.

## Contents <!-- omit in toc -->

- [Solution Overview](#solution-overview)
  - [Architecture](#architecture)
  - [Technologies used](#technologies-used)
- [Key Concepts](#key-concepts)
  - [Environments](#environments)
  - [Testing](#testing)
  - [Observability / Monitoring](#observability--monitoring)
- [How to use the sample](#how-to-use-the-sample)
  - [Prerequisites](#prerequisites)
    - [Software pre-requisites if you use dev container](#software-pre-requisites-if-you-use-dev-container)
  - [Setup and Deployment](#setup-and-deployment)
    - [Deployed Resources](#deployed-resources)
    - [Clean up](#clean-up)
  - [Data Lake Physical layout](#data-lake-physical-layout)
  - [Known Issues, Limitations and Workarounds](#known-issues-limitations-and-workarounds)

---------------------

## Solution Overview

The solution pulls near realtime [Melbourne Parking Sensor data](https://www.melbourne.vic.gov.au/about-council/governance-transparency/open-data/Pages/on-street-parking-data.aspx) from a publicly available REST api endpoint and saves this to [Azure Data Lake Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction). It then validates, cleanses, and transforms the data to a known schema using [Azure Synapse - Spark Pools](https://docs.microsoft.com/en-us/azure/synapse-analytics/spark/apache-spark-overview). A second Spark job then transforms these into a [Star Schema](https://en.wikipedia.org/wiki/Star_schema) which are then loaded into [Azure Synapse - SQL Dedicated Pool (formerly SQLDW)](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-overview-what-is?context=/azure/synapse-analytics/context/context) using [Polybase](https://docs.microsoft.com/en-us/sql/relational-databases/polybase/polybase-guide?view=sql-server-ver15). The entire pipeline is orchestrated with [Azure Synapse Data Pipelines](https://docs.microsoft.com/en-us/azure/data-factory/concepts-pipelines-activities?context=/azure/synapse-analytics/context/context&tabs=synapse-analytics).

### Architecture

The following shows the overall architecture of the solution.

![Architecture](docs/images/architecture.png?raw=true "Architecture")

### Technologies used

It makes use of the following azure services:

- [Azure Synapse Analytics](https://azure.microsoft.com/en-au/services/synapse-analytics/)
- [Azure Data Lake Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)
- [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Log Analytics](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview)

## Key Concepts

### Environments

1. **Sandbox and Dev**- the DEV resource group is used by developers to build and test their solutions. It contains two logical environments - (1) a Sandbox environment per developer so each developer can make and test their changes in isolation prior committing to `main`, and (2) a shared Dev environment for integrating changes from the entire development team. "Isolated" sandbox environment are accomplish through a number of practices depending on the Azure Service.
   - DataLake Gen2 - a "sandbox" file system is created. Each developer creates their own folder within this Sandbox filesystem.
   - AzureSQL or SQLDW - A transient database (restored from DEV) is spun up per developer on demand, if required.
   - Azure Synapse - git integration allows them to make changes to their own branches and debug runs independently.

### Testing

- Integration Testing - These can be ran manually to ensure integration points of the solution function as expected. In this demo solution, an actual Synapse Data Pipeline run is automatically triggered and its output verified.
  - See here for the [integration tests](./tests/integrationtests/).

### Observability / Monitoring

Please check the details [here](docs/observability.md).

## How to use the sample

### Prerequisites

1. [Azure Account](https://azure.microsoft.com/en-au/free/search/?&ef_id=Cj0KCQiAr8bwBRD4ARIsAHa4YyLdFKh7JC0jhbxhwPeNa8tmnhXciOHcYsgPfNB7DEFFGpNLTjdTPbwaAh8bEALw_wcB:G:s&OCID=AID2000051_SEM_O2ShDlJP&MarinID=O2ShDlJP_332092752199_azure%20account_e_c__63148277493_aud-390212648371:kwd-295861291340&lnkd=Google_Azure_Brand&dclid=CKjVuKOP7uYCFVapaAoddSkKcA)
   - *Permissions needed*: ability to create and deploy to an Azure [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview), a [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals), and grant the [collaborator role](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) to the service principal over the resource group.

#### Software pre-requisites if you don't use dev container<!-- omit in toc -->

- For Windows users, [Windows Subsystem For Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
- [az cli 2.6+](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [az cli - application insights extension](https://docs.microsoft.com/en-us/cli/azure/ext/application-insights/monitor/app-insights?view=azure-cli-latest)
  - To install, run `az extension add --name application-insights`
- [Azure DevOps CLI](https://marketplace.visualstudio.com/items?itemName=ms-vsts.cli)
  - To install, run `az extension add --name azure-devops`
- [Python 3+](https://www.python.org/)
- [jq](https://stedolan.github.io/jq/)
- [makepasswd](https://manpages.debian.org/stretch/makepasswd/makepasswd.1.en.html)

#### Software pre-requisites if you use dev container

- [Docker](https://www.docker.com/)
- [VSCode](https://code.visualstudio.com/)
- [Visual Studio Code Remote Development Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

  It is strongly recommended to use dev container for the deployment to avoid environment related issues.

### Setup and Deployment

> **IMPORTANT NOTE:** As with all Azure Deployments, this will **incur associated costs**. Remember to teardown all related resources after use to avoid unnecessary costs. See [here](#deployed-resources) for list of deployed resources. See [here](#clean-up) for information on the clean_up script.
> This deployment was tested using WSL 2 (Ubuntu 20.04) and Debian GNU/Linux 9.9 (stretch)

1. **Initial Setup**
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

       Set the following environment variables:
      - **AZURE_LOCATION** - Azure location to deploy resources. *Default*: `westus`.
      - **AZURE_SUBSCRIPTION_ID** - Azure subscription id to use to deploy resources. *Default*: default azure subscription. To see your default, run `az account list`.
      - **DEPLOYMENT_ID** - string appended to all resource names. This is to ensure uniqueness of azure resource names. *Default*: random five character string.
      - **SYNAPSE_SQL_PASSWORD** - Password of the Synapse SQL instance. *Default*: random string.

   - If you are using **dev container**, follow the below steps:
      - Rename `.envtemplate` under ".devcontainer" folder to `devcontainer.env` and update the values as mentioned above instead of setting those as environment variables.
      - Open the project inside the vscode dev container (see details [here](docs/devcontainer.md)).

     To further customize the solution, set parameters in `arm.parameters` files located in the `infrastructure` folder.

1. **Deploy Azure resources**
   - `cd` into the `single_tech_samples/synapseanalytics/sample2_parking_sensors_infrastructure` folder of the repo

   - Run `./deploy.sh`.
      - This may take around **~30mins or more** to run end to end. So grab yourself a cup of coffee... ☕
      - After a successful deployment, you will find `.env.dev` files containing essential configuration information per environment. See [here](#deployed-resources) for list of deployed resources.
      - Note that if you are using **dev container**, you would run the same script but inside the dev container terminal.

1. **Run Setup notebook in Synapse workspace per environment**

   - Navigate into DEV Synapse workspace notebooks tab and select the *00_setup* notebook.
   - Open the settings for the Spark pool and select the checkbox to "Run as Managed Identity" and save the changes.
     - [Optional] Or you can grant yourself *Storage Data Blob Contributor* to the Synapse main storage (`mdwdopsst2dev<DEPLOYMENT_ID>`).
   - Run this notebook, attaching to the created Spark Pool.
   - Repeat this in the STG and PROD Synapse workspace.

1. **Trigger the Synapse Pipeline**

   - In the **DEV** Synapse workspace, navigate to "Manage > Triggers". Select the `T_Sched` trigger and activate it by clicking on the "Play" icon next to it. Click `Publish` to publish changes.
   - **Optional**. Trigger the Synapse Data Pipelines in the dev environment.
      - In the Synapse workspace of the dev environment, navigate to "Author", then select the `P_Ingest_MelbParkingData`.
      - Select "Trigger > Trigger Now".
      - To monitor the run, go to "Monitor > Pipeline runs".
      ![Pipeline Run](docs/images/SynapseRun.png?raw=true "Pipeline Run]")

Congratulations!! 🥳 You have successfully deployed the solution.

If you've encountered any issues, please review the [Troubleshooting](../../docs/parking_sensors_troubleshooting.md) section and the [Known Issues](#known-issues-limitations-and-workarounds) section. If you are still stuck, please file a Github issue with the relevant error message, error screenshots, and replication steps.

#### Deployed Resources

After a successful deployment, you should have the following resources:

- In Azure, **one Resource Group** with the following Azure resources.
  - **Azure Synapse Workspace** including:
    - **Data Pipelines** - with pipelines, datasets, linked services, triggers deployed and configured correctly.
    - **Notebooks** - Spark, SQL Serverless
    - **Workspace package** (ei. Python Wheel package)
    - **Spark Pool**
      - Workspace package installed
      - Configured to point the deployed Log Analytics workspace, under "Apache Spark Configuration".
    - **SQL Dedicated Pool (formerly SQLDW)** - Initally empty. Release Pipeline should deploy SQL Database objects using the SQL DACPAC.
  - **Data Lake Store Gen2** and a **Service Principal (SP)** with Storage Contributor rights assigned.
  - **Log Analytics Workspace** - including a kusto query on Query explorer -> Saved queries, to verify results that will be looged on Synapse notebooks (notebooks are not deployed yet).
  - **Application Insights**
  - **KeyVault** with all relevant secrets stored.

Notes:

- *These variable groups are currently not linked to KeyVault due to limitations of creating these programmatically. See [Known Issues, Limitations and Workarounds](#known-issues-limitations-and-workarounds)
- Environments and Approval Gates are not deployed as part of this solution. See [Known Issues, Limitations and Workarounds](#known-issues-limitations-and-workarounds)

#### Clean up

This sample comes with an [optional, interactive clean-up script](./scripts/clean_up.sh) which will delete resources with `mdwdops` in its name. It will list resources to be deleted and will prompt before continuing.
> IMPORTANT NOTE: As it simply searches for `mdwdops` in the resource name, it could list resources not part of the deployment! Use with care.

### Data Lake Physical layout

ADLS Gen2 is structured as the following:

```text
    datalake                    <- filesystem
        /sys/databricks/libs    <- contains all libs, jars, wheels needed for processing
        /data
            /lnd                <- Bronze - landing folder where all data files are ingested into.
            /interim            <- Silver - interim (cleansed) tables
            /dw                 <- Gold - final tables 
```

### Known Issues, Limitations and Workarounds

The following lists some limitations of the solution and associated deployment script:

- Azure Synapse SQL Serverless artifacts (ei. Tables, Views, etc) are not currently updated as part of the CICD pipeline.
- Manually publishing the Synapse workspace is required. Currently, this cannot be automated. Failing to publish will mean potentially releasing a stale data pipeline definition in the release pipeline.
  - **Mitigation**: Set Approval Gates between environments. This allows for an opportunity to verify whether the manual publish has been performed.
