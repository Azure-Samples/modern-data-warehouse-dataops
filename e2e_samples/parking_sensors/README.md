[![Build Status](https://dev.azure.com/devlacepub/DataDevOps/_apis/build/status/ddo_transform-ci-artifacts?branchName=master)](https://dev.azure.com/devlacepub/DataDevOps/_build/latest?definitionId=3&branchName=master)

# DataOps - Parking Sensor Demo <!-- omit in toc -->

The sample demonstrate how DevOps principles can be applied end to end Data Pipeline Solution built according to the [Modern Data Warehouse (MDW)](https://azure.microsoft.com/en-au/solutions/architecture/modern-data-warehouse/) pattern.

## Contents <!-- omit in toc -->

- [Solution Overview](#solution-overview)
  - [Architecture](#architecture)
  - [Continuous Integration and Continuous Delivery (CI/CD)](#continuous-integration-and-continuous-delivery-cicd)
  - [Technologies used](#technologies-used)
- [Key Learnings](#key-learnings)
  - [1. Use Data Tiering in your Data Lake.](#1-use-data-tiering-in-your-data-lake)
  - [2. Validate data early in your pipeline.](#2-validate-data-early-in-your-pipeline)
  - [3. Make your data pipelines replayable and idempotent.](#3-make-your-data-pipelines-replayable-and-idempotent)
  - [4. Ensure data transformation code is testable.](#4-ensure-data-transformation-code-is-testable)
  - [5. Have a CI/CD pipeline.](#5-have-a-cicd-pipeline)
  - [6. Secure and centralize configuration.](#6-secure-and-centralize-configuration)
  - [7. Monitor infrastructure, pipelines and data.](#7-monitor-infrastructure-pipelines-and-data)
- [Key Concepts](#key-concepts)
  - [Build and Release Pipeline](#build-and-release-pipeline)
  - [Testing](#testing)
  - [Observability / Monitoring](#observability--monitoring)
    - [Databricks](#databricks)
    - [Data Factory](#data-factory)
- [How to use the sample](#how-to-use-the-sample)
  - [Prerequisites](#prerequisites)
  - [Setup and Deployment](#setup-and-deployment)
    - [Deployed Resources](#deployed-resources)
  - [Data Lake Physical layout](#data-lake-physical-layout)
  - [Known Issues, Limitations and Workarounds](#known-issues-limitations-and-workarounds)

<!-- 
## Contents

1. [Solution Overview](./README.md#Solution-Overview)
2. [Key Learnings](./README.md#key-learnings)
   1. [Use Data-Tiering in your Data Lake](./README.md#1-use-data-tiering-in-your-data-lake)
   2. [Validate data early in your pipeline](./README.md#2-validate-data-early-in-your-pipeline)
   3. [Make your data pipelines replayable and idempotent](./README.md#3-Make-your-data-pipelines-replayable-and-idempotent)
   4. [Ensure data transformation code is testable](./README.md#4-ensure-data-transformation-code-is-testable)
   5. [Have a CI/CD pipeline](./README.md#5-Have-a-CICD-pipeline)
   6. [Secure and centralize configuration](./README.md#6-Secure-and-centralize-configuration)
   7. [Monitor infrastructure, pipelines and data](./README.md#7-Monitor-infrastructure-pipelines-and-data)
3. [Key Concepts](./README.md#key-concepts)
   1. [Build and Release](./README.md#build-and-release)
   2. [Testing](./README.md#testing)
   3. [Observability and Monitoring](./README.md#observability-and-monitoring)
4. [How to use the sample](./README.md#how-to-use-the-sample)
   1. [Prerequisites](./README.md#prerequisites)
   2. [Setup and Deployment](./README.md#setup-and-deployment)
   3. [Deployed resources](./README.md#deployed-resources)
   4. [Known Issues, Limitations and Workarounds](./README.md#known-issues-limitations-workarounds) -->
---------------------

## Solution Overview

The solution pulls near realtime [Melbourne Parking Sensor data](https://www.melbourne.vic.gov.au/about-council/governance-transparency/open-data/Pages/on-street-parking-data.aspx) from a publicly available REST api endpoint and saves this to [Azure Data Lake Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction). It then validates, cleanses, and transforms the data to a known schema using [Azure Databricks](https://azure.microsoft.com/en-au/services/databricks/). A second Azure Databricks job then transforms these into a [Star Schema](https://en.wikipedia.org/wiki/Star_schema) which are then loaded into [Azure Synapse Analytics (formerly SQLDW)](https://azure.microsoft.com/en-au/services/synapse-analytics/) using [Polybase](https://docs.microsoft.com/en-us/sql/relational-databases/polybase/polybase-guide?view=sql-server-ver15). The entire pipeline is orchestrated with [Azure Data Factory](https://azure.microsoft.com/en-au/services/data-factory/).

### Architecture

The following shows the overall architecture of the solution.

![Architecture](../../docs/images/architecture.PNG?raw=true "Architecture")

### Continuous Integration and Continuous Delivery (CI/CD)

The following shows the overall CI/CD process end to end.

![CI/CD](../../docs/images/CI_CD_process.PNG?raw=true "CI/CD")

### Technologies used

It makes use of the following azure services:
- [Azure Data Factory](https://azure.microsoft.com/en-au/services/data-factory/)
- [Azure Databricks](https://azure.microsoft.com/en-au/services/databricks/)
- [Azure Data Lake Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)
- [Azure Synapse Analytics (formerly SQLDW)](https://azure.microsoft.com/en-au/services/synapse-analytics/)
- [Azure DevOps](https://azure.microsoft.com/en-au/services/devops/)


For a detailed walk-through of the solution and key concepts, watch the following video recording:

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/Xs1-OU5cmsw/0.jpg)](https://www.youtube.com/watch?v=Xs1-OU5cmsw")

## Key Learnings
The following summarizes key learnings and best practices demonstrated by this sample solution:

### 1. Use Data Tiering in your Data Lake. 
   - Generally, you want to divide your data lake into three major areas which contain your Bronze, Silver and Gold datasets.
     1. *Bronze* - This is a landing area for your raw datasets with no to minimal data transformations applied, and therefore are optimized for writes / ingestion. Treat these datasets as an immutable, append only store.
     2. *Silver* - These are cleansed, semi-processed datasets. These conform to a known schema and predefined data invariants and might have further data augmentation applied. These are typically used by Data Scientists.
     3. *Gold* - These are highly processed, highly read-optimized datasets primarily for consumption of business users. Typically, these are structured in your standard Fact and Dimension tables.
### 2. Validate data early in your pipeline. 
   - Add data validation between the Bronze and Silver datasets. By validating early in your pipeline, you can ensure all succeeding datasets conform to a specific schema and known data invariants. This also can potentially prevent data pipeline failures in cases of unexpected changes to the input data. 
   - Data that does not pass this validation stage can be rerouted to a Malformed Record store for diagnostic purpose.
   - It may be tempting to add validation prior to landing in the Bronze area of your data lake. This is generally not recommended. Bronze datasets are there to ensure you have as close of a copy of the source system data. This can used to replay the data pipeline for both testing (ei. testing data validation logic) and data recovery purposes (ei. data corruption is introduced due to a bug in the data transformation code and thus pipeline needs to be replayed).
### 3. Make your data pipelines replayable and idempotent. 
   - Silver and Gold datasets can get corrupted due to a number of reasons such as unintended bugs, unexpected input data changes, and more. By making data pipelines replayable and idempotent, you can recover from this state through deployment of code fix and replaying the data pipelines.
   - Idempotency also ensures data-duplication is mitigated when replaying your data pipelines.
### 4. Ensure data transformation code is testable.
   - Abstracting away data transformation code from data access code is key to ensuring unit tests can be written against data transformation logic. An example of this is moving transformation code from notebooks into packages.
   - While it is possible to run tests against notebooks, by shifting tests left you increase developer productivity by increasing the speed of the feedback cycle. 
### 5. Have a CI/CD pipeline.
   - This means including all artifacts needed to build the data pipeline from scratch in source control. This includes infrastructure-as-code artifacts, database objects (schema definitions, functions, stored procedures, etc), reference/application data, data pipeline definitions, and data validation and transformation logic.
   - There should also be a safe, repeatable process to move changes through dev, test and finally production.
### 6. Secure and centralize configuration. 
   - Maintain a central, secure location for sensitive configuration such as database connection strings that can be access by the appropriate services within the specific environment. 
   - Any example of this is securing secrets in KeyVault per environment, then having the relevant services query KeyVault for the configuration.
### 7. Monitor infrastructure, pipelines and data.
   - A proper monitoring solution should be in-place to ensure failures are identified, diagnosed and addressed in a timely manner. Aside from the base infrastructure and pipeline runs, data should also be monitored. A common area that should have data monitoring is the malformed record store.

## Key Concepts

### Build and Release Pipeline

Both Build and Release Pipelines are built using [AzureDevOps](https://dev.azure.com/) (Public instance) and can be viewed using the following links:
- [Build Pipelines](https://dev.azure.com/devlacepub/DataDevOps/_build)
- [Release Pipeline](https://dev.azure.com/devlacepub/DataDevOps/_release)
 
### Testing

- Unit Testing - Standard unit tests which tests small pieces of functionality within your code. Data transformation code should have unit tests.

- Integration Testing - **WIP**. See this [issue](https://github.com/Azure-Samples/modern-data-warehouse-dataops/issues/49).

### Observability / Monitoring

#### Databricks
- [Monitoring Azure Databricks with Azure Monitor](https://docs.microsoft.com/en-us/azure/architecture/databricks-monitoring/)
- [Monitoring Azure Databricks Jobs with Application Insights](https://msdn.microsoft.com/en-us/magazine/mt846727.aspx)

#### Data Factory
- [Monitor Azure Data Factory with Azure Monitor](https://docs.microsoft.com/en-us/azure/data-factory/monitor-using-azure-monitor)
- [Alerting in Azure Data Factory](https://azure.microsoft.com/en-in/blog/create-alerts-to-proactively-monitor-your-data-factory-pipelines/)

## How to use the sample

### Prerequisites
1. [Github account](https://github.com/)
2. [Azure Account](https://azure.microsoft.com/en-au/free/search/?&ef_id=Cj0KCQiAr8bwBRD4ARIsAHa4YyLdFKh7JC0jhbxhwPeNa8tmnhXciOHcYsgPfNB7DEFFGpNLTjdTPbwaAh8bEALw_wcB:G:s&OCID=AID2000051_SEM_O2ShDlJP&MarinID=O2ShDlJP_332092752199_azure%20account_e_c__63148277493_aud-390212648371:kwd-295861291340&lnkd=Google_Azure_Brand&dclid=CKjVuKOP7uYCFVapaAoddSkKcA)
   - *Permissions needed*: ability to create and deploy to an azure [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview), a [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals), and grant the [collaborator role](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) to the service principal over the resource group.
3. [Azure DevOps Account](https://azure.microsoft.com/en-us/services/devops/)
   - *Permissions needed*: ability to create [service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) and [pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/pipelines-get-started?view=azure-devops&tabs=yaml).

#### Software pre-requisites <!-- omit in toc -->
- For Windows users, [Windows Subsystem For Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
- [az cli 2.6+](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [az cli - application insights extension](https://docs.microsoft.com/en-us/cli/azure/ext/application-insights/monitor/app-insights?view=azure-cli-latest)
  - To install, run `az extension add --name application-insights`
- [Azure DevOps CLI](https://marketplace.visualstudio.com/items?itemName=ms-vsts.cli)
  - To install, run `az extension add --name azure-devops`
- [Python 3+](https://www.python.org/)
- [databricks-cli](https://docs.azuredatabricks.net/dev-tools/databricks-cli.html)
- [jq](https://stedolan.github.io/jq/)


NOTE: This deployment was tested using WSL 2 (Ubuntu 18.04) and Debian GNU/Linux 9.9 (stretch)

### Setup and Deployment

**IMPORTANT NOTE:** As with all Azure Deployments, this will incur associated costs. Remember to teardown all related resources after use. See [here](#deployed-resources) for list of deployed resources.

1. **Initial Setup**
   1. Ensure that:
      - You are logged in to the Azure CLI. To login, run `az login`.
      - Azure CLI is targeting the Azure Subscription you want to deploy the resources to.
         - To set target Azure Subscription, run `az account set -s <AZURE_SUBSCRIPTION_ID>`
      - Azure CLI is targeting the Azure DevOps organization and project you want to deploy the pipelines to. 
         - To set target Azure DevOps project, run `az devops configure --defaults organization=https://dev.azure.com/<MY_ORG>/ project=<MY_PROJECT>`
   2. Import this repository into a new Github repo. Importing is necessary for setting up git integration with Azure Data Factory.
   3. Set the following **required** environment variables:
       - **GITHUB_REPO_URL** - URL of your imported github repo. (ei. "https://github.com/devlace/mdw-dataops-import")
       - **GITHUB_PAT_TOKEN** - a Github PAT token. Generate them [here](https://github.com/settings/tokens). This requires "repo" scope.
       
       Optionally, set the following environment variables:
       - **RESOURCE_GROUP_LOCATION** - Azure location to deploy resources. *Default*: `westus`.
       - **AZURE_SUBSCRIPTION_ID** - Azure subscription id to use to deploy resources. *Default*: default azure subscription. To see your default, run `az account list`.
       - **RESOURCE_GROUP_NAME_PREFIX** - name of the resource group. This will automatically be appended with the environment name. For example: `RESOURCE_GROUP_NAME_PREFIX-dev-rg`. *Default*: mdwdo-park-${DEPLOYMENT_ID}.
      - **DEPLOYMENT_ID** - string appended to all resource names. This is to ensure uniqueness of azure resource names. *Default*: random five character string.
       - **AZDO_PIPELINES_BRANCH_NAME** - git branch where Azure DevOps pipelines definitions are retrieved from. *Default*: master.
       - **AZURESQL_SERVER_PASSWORD** - Password of the SQL Server instance. *Default*: semi-random string.

      NOTE: To further customize the solution, set parameters in arm.parameters files located in the `infrastructure` folder.

2. **Deploy Azure resources**
   1. Clone locally the imported Github Repo, then `cd` into the `e2e_samples/parking_sensors` folder of the repo
   2. Run `./deploy.sh`.
      - **NOTE!** This may take around **~30mins or more** to run end to end. So grab yourself a cup of coffee... ☕
      - After a successful deployment, you will find `.env.{environment_name}` files containing essential configuration information per environment. See [here](#deployed-resources) for list of deployed resources.

3. **Setup ADF git integration in DEV Data Factory**
    1. In the Azure Portal, navigate to the Data Factory in the **DEV** environment.
    2. Click "Author & Monitor" to launch the Data Factory portal.
    3. On the landing page, select "Set up code repository". For more information, see [here](https://docs.microsoft.com/en-us/azure/data-factory/source-control).
    4. Fill in the repository settings with the following:
        - Repository type: **Github**
        - Github Account: **your_Github_account**
        - Git repository name: **imported Github repository**
        - Collaboration branch: **master**
        - Root folder: **e2e_samples/parking_sensors/adf**
        - Import Existing Data Factory resource to repository: **Selected**
        - Branch to import resource into: **Use Collaboration**

   **NOTE:** Only the DEV Data Factory should be setup with Git integration. Do **NOT** setup git integration in the STG and PROD Data Factories.

4. **Trigger a Release**

   1. In the Data Factory portal, navigate to "Manage > Triggers". Select the `T_Sched` trigger and activate it by clicking on the "Play" icon next to it. Click `Publish` to publish changes.
      - Publishing a change is **required** to generate the `adf_publish` branch which is required in the next the Release pipelines.
   2. In Azure DevOps, notice a new run of the Build Pipeline (**mdw-park-ci-artifacts**) off `master`.
      - This will build the Python package and SQL DACPAC, then publish these as Pipeline Artifacts.
   3. After completion, this should automatically trigger the Release Pipeline (**mdw-park-cd-release**)
      - This will deploy the artifacts across environments.

Congratulations!! 🥳 You have successfully setup the solution. For next steps, we recommend watching [this presentation](https://www.youtube.com/watch?v=Xs1-OU5cmsw) for a detailed walk-through of the running solution. If you've encountered any issues, please file a Github issue with the relevant error message and replication steps.

#### Deployed Resources

After a successful deployment, you should have the following resources:

- In Azure, **three (3) Resource Groups** (one per environment) each with the following Azure resources.
   - **Data Factory** - with pipelines, datasets, linked services, triggers deployed and configured correctly per environment.
   - **Data Lake Store Gen2** and a **Service Principal (SP)** with Storage Contributor rights assigned.
   - **Databricks workspace** 
     - notebooks uploaded at `/notebooks` folder in the workspace
     - SparkSQL tables created
     - ADLS Gen2 mounted at `dbfs:/mnt/datalake` using the Storage Service Principal.
   - **Azure Synapse (formerly SQLDW)** - currently, empty. The Release Pipeline will deploy the SQL Database objects.
   - **Application Insights**
   - **KeyVault** with all relevant secrets stored.
   - All above Azure resources are tagged with correct Environment.
 - In Azure DevOps
   - **Four (4) Azure Pipelines**
     - mdw-park-cd-release - Release Pipeline
     - mdw-park-ci-artifacts - Build Pipeline
     - mdw-park-ci-qa-python - "QA" pipeline runs on PR to master
     - mdw-park-ci-qa-sql - "QA" pipeline runs on PR to master
   - **Three (3) Variables Groups** - one per environment
   - **Four (4) Service Connections**
     - **Three Azure Service Connections** (one per environment) each with a **Service Principal** with Contributor rights to the corresponding Resource Group.
     - **Github Service Connection** for retrieving code from Github
<!--TODO: Add Cleanup script-->

### Data Lake Physical layout

ADLS Gen2 is structured as the following:

------------

    datalake                    <- filesystem
        /libs                   <- contains all libs, jars, wheels needed for processing
        /data
            /lnd                <- Bronze - landing folder where all data files are ingested into.
            /interim            <- Silver - interim (cleansed) tables
            /dw                 <- Gold - final tables 
------------

### Known Issues, Limitations and Workarounds
- Databricks KeyVault-backed secrets scopes can only be create via the UI, cannot be created programmatically and was not incorporated in the automated deployment of the solution.
  - **Workaround**: Deployment uses normal Databricks secrets with the downside of duplicated information. If you wish, you many manually convert these to KeyVault-back secret scopes.
- Azure DevOps Variable Groups linked to KeyVault can only be created via the UI, cannot be created programmatically and was not incorporated in the automated deployment of the solution.
  - **Workaround**: Deployment add sensitive configuration as "secrets" in Variable Groups with the downside of duplicated information. If you wish, you may manually link a second Variable Group to KeyVault to pull out the secrets.
