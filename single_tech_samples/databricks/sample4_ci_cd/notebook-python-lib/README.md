# Testing a Databricks Python Notebook with imported custom libraries

## Overview

This sample demonstrates:

1. how to import custom python libraries/modules into a databricks notebook
2. how to use unit tests to test the python modules and use [nutter](https://github.com/microsoft/nutter) to perform integration test on the notebook
3. how to package the python modules & notebook, execute tests and publish the results as part of Build and Release pipelines

## How to use this sample

### Prerequisites

- [Azure DevOps account](https://azure.microsoft.com/en-au/services/devops/) for running pipelines
- [Github account](https://github.com/) for source control
- [Azure Databricks workspace](https://azure.microsoft.com/en-au/services/databricks/) with an [existing cluster](https://docs.microsoft.com/en-us/azure/databricks/clusters/create) running. Note: Refer to [Sample 1](../../sample1_basic_azure_databricks_environment/README.md) and [Sample 3](../../sample3_cluster_provisioning_and_data_access/README.md) to setup these resource.

### Setup and deployment

1. Clone (or import) this repository.
1. In Azure DevOps, [define a Variable Group](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml) called `mdwdo-dbx-npl-test` with the following variables:
    1. **databricksDomain** - The databricks host in this format: `https://adb-123456789xxxx.x.azuredatabricks.net`
    1. **databricksToken** - Databricks PAT token.
    1. **databricksNotebookPath** - Where in the databricks workspace the notebook will be uploaded as part of the Release pipeline. ei. `/Shared/notebooks`
    1. **databricksClusterId** - Databricks cluster id that will be used to run the notebooks.
1. In Azure DevOps, [create two Azure Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline?view=azure-devops&tabs=java%2Ctfs-2018-2%2Cbrowser) based on the following azure-pipeline definitions:
    1. `devops/cd-pipeline.yaml` - name this `mdw-dbx-npl-ci-pipeline`
    1. `devops/ci-pipeline.yaml` - name this `mdw-dbx-npl-cd-pipeline`
1. Run the `mdw-dbx-npl-ci-pipeline`, first then the `mdw-dbx-npl-cd-pipeline`. Currently, these are not automatically triggered and needs to be triggered manually.

### Notes

In order for this sample to work from the Databricks Workspace and not from pipeline, follow the below steps:

1. Import only the notebooks and python files in the same structure as in the `notebook-python-lib` folder
2. The individual python modules can run as is with no additional changes.
3. In order to execute the unit tests manually from the databricks workspace,
    1. Add a command to import the modules in the same notebook as the test before running the tests
        1. `%run /path/to/python_module` - In this sample, this command would be `%run ../common/module_a` while executing the `test_module_a.py` notebook. This command imports the corresponding python module in the same notebook.
4. Before executing the `main_notebook.py`, you need to follow the below steps:
    1. Import the packaged wheel file i.e. library created from the python modules into the workspace
        1. Option1: Use the Workspace UI
            1. Workspace -> Import -> Import Library -> Upload -> PythonWhl -> browse and upload the packaged library file -> Click Create
        2. Option2: Use the Databricks CLI
            1. databricks fs cp "local_library_file_path" "dbfs:/FileStore/jars" --recursive --overwrite
    2. Install the library in the cluster/notebook
        1. Option1: (Cluster scoped) Use the workspace UI
            1. Clusters -> Select the cluster -> Libraries tab -> Choose the imported library -> Click Install
        2. Option2: (Notebook scoped) Add and Run the following command in the notebook:
            1. `%pip install <library_path>` - Fetch the library path when you import the library in the above step. It usually looks like  `dbfs:/FileStore/jars/.../library-name.whl`
        3. Option3: Use the Databricks CLI command:
            1. `databricks libraries install --cluster-id $CLUSTER_ID --whl file` where `file` is the absolute path of the wheel file in the dbfs system
    3. Once the python custom libraries are installed in the workspace notebok, simply run the `main_notebook` to execute the python modules.
