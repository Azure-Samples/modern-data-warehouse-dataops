# ADF Integration Tests

This makes use of [PyTest framework](https://docs.pytest.org/en/latest/) to execute integration tests. In general, the tests do the following:

1. Trigger target Azure Data Factory pipeline.
2. Verify pipeline run has succeeded and data has been copied as expected.

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

Azure Storage Account connection information:

- **AZ_STORAGE_ACCOUNT_CONNECTIONSTRING**

Additional *optional* configuration:

- **AZURE_DATAFACTORY_POLL_INTERVAL** - Poll interval in seconds for checking for pipeline status. *Default*: 5.

## Code structure

The code is organized as follows:

- `tests/`
  - `dataconnectors/` - Data connector specific fixtures, subdivided into modules.
    - `blob_storae.py` - Fixture for creating connection client for blob storage.
  - `test_*.py` - contain all test cases
