# Python Package - ddo_transform

## Development setup

### Pre-requisites

- [Docker](https://www.docker.com/)
- [VSCode](https://code.visualstudio.com/)

### Steps to setup Development environment

> For [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) users, note that performance in Devcontainers is significantly better if the repository resides on the WSL file system, and not on the Windows file system.

1. Open VSCode from the **root of the Python project**. That is, the root of your VSCode workspace needs to be at `e2e_samples/parking_sensors/src/ddo_transform`. It should have the `.devcontainer` folder.
2. Create an `.env` file. Optionally, set the following environment variables.
    - If you will be uploading the package to a Databricks workspace as part of the Development cycle, you need to set the following:
      - **DATABRICKS_HOST** - Databricks workspace url (ei. [https://australiaeast.azuredatabricks.net](https://australiaeast.azuredatabricks.net))
      - **DATABRICKS_TOKEN** - PAT token to databricks workspace
      - **DATABRICKS_DBFS_PACKAGE_UPLOAD_PATH** - Path in the DBFS where the python package whl file will be uploaded when calling `make uploaddatabricks`.
      - **DATABRICKS_CLUSTER_ID** - Cluster Id of Databricks cluster where package will be installed when calling `make installdatabricks`
3. In VSCode command pallete (`ctrl+shift+p`), select `Remote-Containers: Reopen in container`. First time building the Devcontainer may take a while.
4. Run `make` in integrated terminal to see options.
    ![makefile](./docs/images/make.png)

### Debugging unit tests

The Devcontainer should have ms-python extension installed and .vscode all the necessary settings. All you need to do is [discover tests](https://code.visualstudio.com/docs/python/testing), enabling the Pytest framework.

> Note: on the first launch, the test window may show a pytest discovery error. If that
> occurs, relaunch VSCode.

### Dependency and artifact versions

When determining versions of base Docker images and dependency packages, make sure to align versions with the ones used in the Databricks runtime version currently used in deploymen.

The sample is currently aligned to [Databricks Runtime 12.2 LTS](https://docs.databricks.com/release-notes/runtime/12.2.html). This includes:

- Java 8
- Scala 2.12
- Python 3.9.5
