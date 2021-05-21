# Databricks CI/CD - MLflow Experiment

This sample demonstrates how to deploy MLflow Experiments/Jobs to Azure Databricks as well as how to do unit test and integration test via CI/CD pipeline.

Note that we use dbx CLI to deploy MLflow experiments/jobs,  for more information, please see [this repo](https://github.com/databrickslabs/cicd-templates).

## How to use this sample

### Prerequisites

- [Azure DevOps account](https://azure.microsoft.com/en-au/services/devops/)
- [Github account](https://github.com/)
- Provision Key valuts instance, Databricks workspace as well as Spark cluster via [this provisioning pipeline](https://github.com/Azure-Samples/modern-data-warehouse-dataops/blob/single-tech/databricks-ops/single_tech_samples/databricks/sample4_ci_cd/devops/iac-create-environment-pipeline-arm.yml)
  - In Azure DevOps, [create three Azure Resource Manager service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops) with the naming convention `mdwdo-dbx-serviceconnection-<environment>` (where `<environment>` stands for `dev`, `stg`, `prod`).
  - In Azure DevOps, define three [Variable Groups](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml) with the naming convention `mdwdo-dbx-release-<environment>` (where `<environment>` stands for `dev`, `stg`, `prod`) with the following variables:
    - **AZURE_RESOURCE_GROUP_LOCATION** - Azure region where the resources will be deployed. (e.g. australiaeast, eastus, etc.).
    - **AZURE_RESOURCE_GROUP_NAME** - Name of the containing resource group.
    - **AZURE_SUBSCRIPTION_ID** - Subscription ID of the Azure subscription where the resources will be deployed.
    - **AZURE_SERVICE_CONNECTION** - Name of the Azure Resource Manager service connection to the Azure account where resources will be deployed.
    - **DEPLOYMENT_PREFIX** - Prefix for the resource names which will be created as a part of this deployment.
    > Note:
         - DEPLOYMENT_PREFIX can contain numbers and lowercase letters only. This is to keep in line with the naming standards allowed for Azure Storage Account.
         - The variable names in variable groups have been constructed in a manner that allows them to be injected into pipeline tasks as [environment variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#environment-variables). For example, on UNIX systems (macOS and Linux), environment variables have the format `$VARIABLE_NAME`.
  - The following secrets are stored in Azure Key Vault as part of provisioning setup:
    - DatabricksHost
    - DatabricksToken
    - HighConcurrencyDatabricksClusterID
    - StandardDatabricksClusterID
    - StorageAccountKey1
    - StorageAccountKey2

### Setup and deployment

1. Clone (or import) this repo.
1. In Azure DevOps, [create Azure Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline?view=azure-devops&tabs=java%2Ctfs-2018-2%2Cbrowser) based on below azure-pipeline definitions:
    - `devops/ci-pipeline.yml` - name this `mdw-dbx-pyspark-ci-pipeline`
    - `devops/cd-pipeline.yml` - name this `mdw-dbx-pyspark-cd-pipeline`
1. Run the `mdw-dbx-pyspark-ci-pipeline` manually or trigger it by commit changes to checkout branch; then trigger `mdw-dbx-pyspark-cd-pipeline` manually if UT runs good in former pipeline.
1. For running unit test locally, Spark and Hadoop setup is required.
    - Download Spark source from [here](https://www.apache.org/dyn/closer.lua/spark/spark-3.1.1/spark-3.1.1-bin-hadoop2.7.tgz) if it not there yet.
    - Extract the download file then set/export SPARK_HOME to the extracted path.
    - Set/export HADOOP_HOME to a target path like **/Hadoop.
    - Download Hadoop  __winutils__  from [here](https://github.com/cdarlint/winutils) and save it to HADOOP_HOME path.
1. Both MLflow source and integration tests are deployed to target Databricks workspace as jobs and linked experiments via dbx CLI.
    - MLflow source and tests jobs are maintained in  __jobs__  key of /conf/deployment*.json file
    - Once the deployment stage of `mdw-dbx-pyspark-cd-pipeline` pipeline has done, which means relevant integrtaion tests in previous stages have passed, and we're ready to trigger source job run either via workspace UI or use dbx CLI like below.

```sh
        # 1. Set environment variable DATABRICKS_TOKEN and DATABRICKS_HOST before running 'dbx configure' command
        # 2. dbx configure command is recommended to run under project root path
        dbx configure
        dbx launch --job=$jobName
```
