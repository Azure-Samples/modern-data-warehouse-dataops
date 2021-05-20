# Databricks CI/CD - MLflow Experiment

This sample demonstrates how to deploy MLflow Experiments/Jobs to Azure Databricks as well as how to do unit test and integration test via CI/CD pipeline.

Note that we use dbx CLI to deploy MLflow experiments/jobs,  for more information, please see [this repo](https://github.com/databrickslabs/cicd-templates).

## How to use this sample

### Prerequisites

- [Azure DevOps account](https://azure.microsoft.com/en-au/services/devops/)
- [Github account](https://github.com/)
- [Azure Databricks workspace](https://azure.microsoft.com/en-au/services/databricks/) with an [existing cluster](https://docs.microsoft.com/en-us/azure/databricks/clusters/create) running.

### Setup and deployment

1. Clone (or import) this repo.
1. In Azure DevOps, [define a Variable Group](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml) called `mdwdo-dbx-pyspark-test` with the following variables:
    - **databricksHost** - The databricks host in this format: `https://adb-123456789xxxx.x.azuredatabricks.net`
    - **databricksToken** - Databricks PAT token.
    - **databricksClusterId** - Databricks cluster id that will be used to run the notebooks.
1. In Azure DevOps, [create Azure Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline?view=azure-devops&tabs=java%2Ctfs-2018-2%2Cbrowser) based on below azure-pipeline definitions:
    - `devops/azure-pipelines.yaml` - name this `mdw-dbx-pyspark-cicd-pipeline`
1. Run the `mdw-dbx-pyspark-cicd-pipeline` manually or trigger it by commit changes to master branch.
1. For running unit test locally, Spark and Hadoop setup is required.
    - Download Spark source from [here](https://www.apache.org/dyn/closer.lua/spark/spark-3.1.1/spark-3.1.1-bin-hadoop2.7.tgz) if it not there yet.
    - Extract the download file then set/export SPARK_HOME to the extracted path.
    - Set/export HADOOP_HOME to a target path like **/Hadoop.
    - Download Hadoop  __winutils__  from [here](https://github.com/cdarlint/winutils) and save it to HADOOP_HOME path.
1. Both MLflow source and integration tests are deployed to target Databricks workspace as jobs and linked experiments via dbx CLI.
    - MLflow source and tests jobs are maintained in  __jobs__  key of /conf/deployment*.json file
    - Once the deployment stage of CI/CD pipeline has done, which means relevant unit tests and integrtaion tests in previous stages have passed, and we're ready to trigger source job run either via workspace UI or use dbx CLI like below.

```sh
        # Set environment variable DATABRICKS_TOKEN and DATABRICKS_HOST before running 'dbx configure' command
        dbx configure
        dbx launch --job=$jobName
```
