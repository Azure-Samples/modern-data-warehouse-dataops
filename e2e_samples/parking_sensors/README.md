[![Build Status](https://dev.azure.com/devlacepub/DataDevOps/_apis/build/status/ddo_transform-ci-artifacts?branchName=master)](https://dev.azure.com/devlacepub/DataDevOps/_build/latest?definitionId=3&branchName=master)

# DataOps - Parking Sensor Demo

The sample demonstrate how DevOps principles can be applied end to end Data Pipeline Solution built according to the [Modern Data Warehouse (MDW)](https://azure.microsoft.com/en-au/solutions/architecture/modern-data-warehouse/) pattern.

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
   4. [Known Issues, Limitations and Workarounds](./README.md#known-issues-limitations-workarounds)
---------------------


## Solution Overview

The solution pulls near realtime [Melbourne Parking Sensor data](https://www.melbourne.vic.gov.au/about-council/governance-transparency/open-data/Pages/on-street-parking-data.aspx) from a publicly available REST api endpoint and saves this to [Azure Data Lake Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction). It then validates, cleanses, and transforms the data to a known schema using [Azure Databricks](https://azure.microsoft.com/en-au/services/databricks/). A second Azure Databricks job then transforms these into a [Star Schema](https://en.wikipedia.org/wiki/Star_schema) which are then loaded into [Azure Synapse Analytics (formerly SQLDW)](https://azure.microsoft.com/en-au/services/synapse-analytics/) using [Polybase](https://docs.microsoft.com/en-us/sql/relational-databases/polybase/polybase-guide?view=sql-server-ver15). The entire pipeline is orchestrated with [Azure Data Factory](https://azure.microsoft.com/en-au/services/data-factory/).

### Architecture

The following shows the overall architecture of the solution.

![Architecture](../../docs/images/architecture.PNG?raw=true "Architecture")

### Continous Integration and Continous Delivery (CI/CD)

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
   - Generally, you want to divide your data lake into three major areas which contain your Bronze, Silver and Gold Datasets.
     1. *Bronze* - This is a landing area for your raw datasets with no to minimal data transformations applied, and therefore are optimized for writes / ingestion. Treat these datasets as an immutable, append only store.
     2. *Silver* - These are cleansed, semi-processed datasets. These conform to a known schema and predefinedd data invariants and might have further data augmentation applied. These are typically used by Data Scientists.
     3. *Gold* - These are highly processed, highly read-optimized datasets primarily for consumption of business users. Typically, these are structured in your standard Fact and Dimension tables.
### 2. Validate data early in your pipeline. 
   - Add data validation between the Bronze and Silver datasets. By validating early in your pipeline, you can ensure all succeeding datasets conform to a specific schema and known data invariants. This also can potentially prevent data pipeline failures in cases of unexpected changes to the input data. 
   - Data that does not pass this validation stage can be rerouted to a Malformed Record store for diagnostic purpose.
   - It may be tempting to add validation prior to landing in the Bronze area of your data lake. This is generally not recommended. Bronze datasets are there to ensure you have as close of a copy of the source system data. This can used to replay the data pipeline for both testing (ei. testing data validation logic) and data recovery purposes (ei. data corruption is introduced due to a bug in the data transformation code and thus pipeline needs to be replayed).
### 3. Make your data pipelines replayable and idempotent. 
   - Silver and Gold datasets can get corrupted due to a number of reasons such as unintended bugs, unexpected input data changes, and more. By making data pipelines replayable and idempotent, you can recover from this state through deployment of code fix and replaying the data pipelines.
   - Idempotency also ensures data-duplication is mitigated when replaying your data pipelines.
### 4. Ensure data transformation code is testable.
   - Abstracting away data transformation code from data access code is key to ensuring unit tests can be written againsts data transformation logic. An example of this is moving tranformation code from notebooks into packages.
   - While it is possible to run tests against notebooks, by shifting tests left you increase developer productivity by increasing the speed of the feedback cycle. 
### 5. Have a CI/CD pipeline.
   - This means including all artifacts needed to build the data pipeline from scratch in source control. This includes infrastructure-as-code artifacts, database objects (schema definitions, functions, stored procedures, etc), reference/application data, data pipeline defintions, and data validation and transformation logic.
   - There should also be a safe, repeatable process to move changes through dev, test and finally production.
### 6. Secure and centralize configuration. 
   - Maintain a central, secure location for sensitive configuration such as database connection strings that can be access by the approriate services within the specific environment. 
   - Any example of this is securing secrets in KeyVault per environment, then having the relevant services query KeyVault for the configuration.
### 7. Monitor infrastructure, pipelines and data.
   - A proper monitoring solution should be inplace to ensure failures are identified, diagnosed and addressed in a timely manner. Aside from the base infrastructure and pipeline runs, data should also be monitored. A common area that should have data monitoring is the malformed record store.

## Key Concepts

### Build and Release Pipeline

Both Build and Release Pipelines are built using [AzureDevOps](https://dev.azure.com/) (Public instance) and can be view using the following links:
- [Build Pipelines](https://dev.azure.com/devlacepub/DataDevOps/_build)
- [Release Pipeline](https://dev.azure.com/devlacepub/DataDevOps/_release)

More information [here](./docs/CI_CD.md).
 
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
1. Github Account
2. Azure DevOps Account + Project
3. Azure Account

#### Software pre-requisites:
1. For Windows users, [Windows Subsystem For Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
2. [az cli 2.x](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. [az cli - storage-preview extension](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-directory-file-acl-cli)
4. [Python 3+](https://www.python.org/)
5. [databricks-cli](https://docs.azuredatabricks.net/dev-tools/databricks-cli.html)
6. [jq](https://stedolan.github.io/jq/)

NOTE: This deployment was tested using WSL (Ubuntu 16.04) and Debian GNU/Linux 9.9 (stretch)

### Setup and Deployment

1. Fork this repository. Forking is necessary if you want to setup git integration with Azure Data Factory.
2. **Deploy Azure resources.** 
    1. Clone the forked repository and `cd` into the root of the repo
    2. Run `./deploy.sh`.
        - You can customize the solution by setting the following environment variables:
          - DEPLOYMENT_ID - string appended to all resource names. Default: random five character string.
          - RESOURCE_GROUP_NAME_PREFIX - name of the resource group. This will be prefixed with environment name. For example: `RESOURCE_GROUP_NAME_PREFIX-dev-rg`. Default: mdw-dataops-parking-${DEPLOYMENT_ID}.
          - RESOURCE_GROUP_LOCATION - Azure location to deploy resources. Default: westus.
          - AZURE_SUBSCRIPTION_ID - Azure subscription id to use to deploy resources. Default: default azure subscript. To see your default, run `az account list`.
          - To further customize the solution, set parameters in arm.parameters files locted in the `infrastructure` folder.
        - After a successful deployment, you will find `.env.{environment_name}` files containing essential configuration information per environment.

3. **Setup ADF git integration in DEV Data Factory**
    1. In the Azure Portal, navigate to the Data Factory in the **DEV** environment.
    2. Click "Author & Monitor" to launch the Data Factory portal.
    3. On the landing page, select "Set up code repository". For more information, see [here](https://docs.microsoft.com/en-us/azure/data-factory/source-control).
    4. Fill in the repository settings with the following:
        - Repository type: **Github**
        - Github Account: ***your_Github_account***
        - Git repository name: **forked Github repository**
        - Collaboration branch: **master**
        - Root folder: **/adf**
        - Import Existing Data Factory resource to respository: **Unselected**
    5. Navigating to "Author" tab, you should see all the pipelines deployed.
    6. Select `Connections` > `Ls_KeyVault`. Update the Base Url to the KeyVault Url of your DEV environment.
    7. Select `Connections` > `Ls_AdlsGen2_01`. Update URL to the ADLS Gen2 Url of your DEV environment.
    8. Click `Publish` to publish changes.

4. **Setup Build Pipelines.** You will be creating two build pipelines, one which will trigger for every pull request which will run Unit Testing + Linting, and the second one which will trigger on every commit to master and will create the actual build artifacts for release.
    1. In Azure DevOps, navigate to `Pipelines`. Select "Create Pipeline".
    2. Under "Where is your code?", select Github (YAML).
        - If you have not yet already, you maybe prompted to connect your Github account. See [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/github?view=azure-devops&tabs=yaml#grant-access-to-your-github-repositories) for more information.
    3. Under "Select a repository", select your forked repo.
    4. Under "Configure your pipeline", select "Existing Azure Pipelines YAML file".
        - Branch: master
        - Path: `/src/ddo_transform/azure-pipelines-ci-qa.yaml`
    5. Select `Run`.
    6. Repeat steps 1-4, but select as the path `/src/ddo_transform/azure-pipelines-ci-artifacts`.

5. **Setup Release Pipelines**
    - **WIP**. Release Pipelines set to be converted to YAML format. See this [issue](https://github.com/Azure-Samples/modern-data-warehouse-dataops/issues/48).

### Deployed resources

After a successfuly deployment, you should have the following resources deployed:
- Three Resource Groups (one per environment) each with the following Azure resources.
    - Data Factory (empty) - *next steps will deploy actual data pipelines*.
    - Data Lake Store Gen2 and Service Principal with Storage Contributor rights assigned.
    - Databricks workspace - notebooks uploaded, SparkSQL tables created, and ADLS Gen2 mounted using SP.
    - KeyVault with all secrets stored.
    - Notes: Azure Synapse (formerly SQLDW) is not yet automatically deployed as part of script. See this [issue](https://github.com/Azure-Samples/modern-data-warehouse-dataops/issues/43)

All Azure resources are tagged with correct Environment.


#### Data Lake Physical layout

ADLS Gen2 is structured as the following:

------------

    datalake                    <- filesystem
        /libs                   <- contains all libs, jars, wheels needed for processing
        /data
            /lnd                <- Bronze - landing folder where all data files are ingested into.
            /interim            <- Silver - interim (cleanesed) tables
            /dw                 <- Gold - final tables 
------------

### Known Issues, Limitations and Workarounds
- Databricks KeyVault-backed secrets scopes can only be create via the UI, and thus cannot be created programmatically and was not incorporated in the automated deployment of the solution.
  - **Workaround**: Use normal Databricks secrets with the downside of duplicated information.
- Data Factory Databricks Linked Service does not support dynamic configuration, thus needing a manual step to point to new cluster during deployment of pipeline to a new environment.
  - **Workaround**: Alternative is to create an on-demand cluster however this may introduce latency issues with cluster spin up time. Optionally, user can manually update Linked Service to point to correct cluster.
