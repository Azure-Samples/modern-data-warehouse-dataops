# Integration test suite for ADF

This makes use of [PyTest framework](https://docs.pytest.org/en/latest/) to execute integration tests. In general, the tests do the following:
1. Upload known input test data (located in `/tests/data`) into specified data sources (ei. blob storage) necessary for the pipeline to run.
2. Trigger pipeline to consume uploaded test data.
3. Verify pipeline run has succeeded and data outputs are valid.

Note, this package does **not** deploy the actual integration test environment and assumes an integration tests environment is already provisioned.

## Environment Variables

The following environment variables must be set:

Service principal account details used to connect to Azure:
 - **AZURE_SERVICE_PRINCIPAL_ID**
 - **AZURE_SERVICE_PRINCIPAL_SECRET**
 - **AZURE_SERVICE_PRINCIPAL_TENANT_ID**
  
Azure resources details:
  - **AZURE_SUBSCRIPTION_ID**
  - **AZURE_RESOURCE_GROUP_NAME**
  - **AZURE_DATAFACTORY_NAME**
  - **AZURE_STORAGE_CONNECTION_STRING** - An ADF input. Connection string to storage account where CSV test data gets uploaded.
  - **AZURE_DATALAKE_STORAGE_CONNECTION_STRING** - An ADF input. Connection string to storage account where AVRO test data gets uploaded.

Additional optional configuration:
  - **AZURE_DATAFACTORY_POLL_INTERVAL** - Poll interval in seconds for checking for pipeline status. *Default*: 5.
  - **AZURE_BLOB_STORAGE_TEST_DATA_CONTAINER** - container where test data gets uploaded. *Default*: integration-test-data.

## Development setup

### Pre-requisites:
- [Docker](https://www.docker.com/)
- [VSCode](https://code.visualstudio.com/)
  
### Steps to setup Development environment:

1. Open VSCode from the **root of the Python project**. That is, the root of your VSCode workspace needs to be at `/test`. It should have `.devcontainer` and `.vscode` folders.
2. Create an `.env` file. Set the environment variables as listed out in "Environment Variables" section.
3. In VSCode command pallete (`ctrl+shift+p`), select `Remote-Containers: Reopen in container`. First time building the Devcontainer may take a while.
4. Run `pytest` to run tests.


## Code structure

The code is organized as follows:
- `tests/`
  - `conftest.py` - Common Pytest [Fixtures](https://docs.pytest.org/en/latest/fixture.html), specific related to Azure Data Factory. It also imports modules in `connectors/`
  - `dataconnectors/` - Data connector specific fixtures, subdivided into modules.
  - `data/` - all test data used in test cases
  - `test_*.py` - contain all test cases

## Caching pipeline runs

Because ADF pipelines can be expensive to run, the `adf_pipeline_run` fixture allows you to cache `pipeline_runs` by specifying the `cached_run_name` variable. Pipeline runs are identified by a combination of `pipeline_name` and `cached_run_name`. This is helpful is you want to create multiple test cases against the same pipeline_run without the need to (1) rerun the entire pipeline or (2) mixing all assert statements in the same `test_` case function.

To force a rerun with the same pipeline_name and cached_run_name, use `rerun=True`.

For example:
```python
# Call adf_pipeline_run specifying cached_run_name variable.
this_first_run = adf_pipeline_run(pipeline_name="pipeline_foo", run_inputs={}, cached_run_name="run_bar")

# Call adf_pipeline_run again, with same pipeline_name and cached_run_name
# This will NOT trigger an actual ADF pipeline run, and will instead return this_first_run object.
# Note: run_inputs are not checked to determine if run is cached.
this_second_run = adf_pipeline_run(pipeline_name="pipeline_foo", run_inputs={}, cached_run_name="run_bar")
this_first_run == this_second_run  # True

# To force a rerun, set rerun=True.
this_third_run = adf_pipeline_run(pipeline_name="pipeline_foo", run_inputs={}, cached_run_name="run_bar", rerun=True)
this_first_run != this_third_run  # False

```