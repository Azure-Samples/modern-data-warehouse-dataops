# Databricks CI/CD - Testing notebooks as part of a CI/CD pipeline

This sample demonstrates how to automate testing of Databricks notebooks which have inline `assert` statements within the notebook itself. The tests are run through a Build and Release pipeline. The test results are also published as part of the pipeline.

The sample Databricks notebook under test can be found [here](./notebooks/main_notebook.py). Notice a single assert statement at the end.

For more information, see [here](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/ci-cd/ci-cd-azure-devops#run-integration-tests-from-an-azure-databricks-notebook).

## How to use this sample

### Prerequisites

- [Azure DevOps account](https://azure.microsoft.com/en-au/services/devops/)
- [Github account](https://github.com/)
- [Azure Databricks workspace](https://azure.microsoft.com/en-au/services/databricks/) with an [existing cluster](https://docs.microsoft.com/en-us/azure/databricks/clusters/create) running.

### Setup and deployment

1. Clone (or import) this repo.
1. In Azure DevOps, [define a Variable Group](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml) called `mdwdo-dbx-nd-test` with the following variables:
    1. **databricksDomain** - The databricks host in this format: `https://adb-123456789xxxx.x.azuredatabricks.net`
    1. **databricksToken** - Databricks PAT token.
    1. **databricksNotebookPath** - Where in the databricks workspace the notebook will be uploaded as part of the Release pipeline. ei. `/Shared/notebooks`
    1. **databricksClusterId** - Databricks cluster id that will be used to run the notebooks.
1. In Azure DevOps, [create two Azure Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline?view=azure-devops&tabs=java%2Ctfs-2018-2%2Cbrowser) based on the following azure-pipeline definitions:
    1. `devops/cd-pipeline.yaml` - name this `mdw-dbx-nd-ci-pipeline`
    1. `devops/ci-pipeline.yaml` - name this `mdw-dbx-nd-cd-pipeline`
1. Run the `mdw-dbx-nd-ci-pipeline`, first then the `mdw-dbx-nd-cd-pipeline`. Currently, these are not automatically triggered and needs to be run manually.
