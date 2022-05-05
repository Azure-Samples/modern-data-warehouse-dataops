# Integration test suite for ADF

This makes use of [PyTest framework](https://docs.pytest.org/en/latest/) to execute integration tests. In general, the tests do the following:

1. Upload known input test data ([Public API](https://data.melbourne.vic.gov.au/resource/)) into specified data sources (ei. blob storage) necessary for the pipeline to run.
2. Trigger pipeline to consume uploaded test data.
3. Verify pipeline run has succeeded and data outputs are valid.

Note, this package does **not** deploy the actual integration test environment and assumes an integration tests environment is already provisioned.

## Environment Variables

The following environment variables must be set:

Service principal account details used to connect to Azure:

- **AZ_SERVICE_PRINCIPAL_ID**
- **AZ_SERVICE_PRINCIPAL_SECRET**
- **AZ_SERVICE_PRINCIPAL_TENANT_ID**

Azure Data Factory:

- **AZ_SUBSCRIPTION_ID**
- **AZ_RESOURCE_GROUP_NAME**
- **AZ_DATAFACTORY_NAME**

Azure Data Factory output(s) connection information:

- **AZ_SQL_SERVER_NAME**
- **AZ_SQL_SERVER_USERNAME**
- **AZ_SQL_SERVER_PASSWORD**
- **AZ_SQL_DATABASE_NAME**

Additional *optional* configuration:

- **AZURE_DATAFACTORY_POLL_INTERVAL** - Poll interval in seconds for checking for pipeline status. *Default*: 5.

## Development setup

### Pre-requisites

- [Docker](https://www.docker.com/)
- [VSCode](https://code.visualstudio.com/)
  
### Steps to setup Development environment

1. Open VSCode from the **root of the Python project**. That is, the root of your VSCode workspace needs to be at `/test`. It should have `.devcontainer` and `.vscode` folders.
2. Copy `.envtemplate` file as new `.env` file. Set the environment variables as listed out in `.envtemplate` file.
3. In VSCode command pallete (`ctrl+shift+p`), select `Remote-Containers: Reopen in container`. First time building the Devcontainer may take a while.
4. Run `pytest` to run tests.

## Code structure

The code is organized as follows:

- `tests/`
  - `conftest.py` - Common Pytest [Fixtures](https://docs.pytest.org/en/stable/fixture.html).
  - `dataconnectors/` - Data connector specific fixtures, subdivided into modules.
  - `test_*.py` - contain all test cases
