# DevOps Pipelines

## Required Variables

The following variables needs to be set in your Release Pipelines.

### Solution Specific Variables

- devAdfName - Name of the of ADF instance which has Git integration enabled.

### Environment Specific Variables

These variables typically changes across environments and are best stored in environment-scoped Variables Groups.

- **azureLocation** - location of deployed resources. ei. "Australia East"
- **rgName** - Target Resource Group of the deployment
- **databricksNotebookPath** - Databricks workspace path where notebooks will be uploaded. (ei. /myworkspace/notebooks)
- **databricksDbfsLibPath** - Databricks DBFS path where Python whl files will be uploaded. (ei. dbfs:/mnt/datalake/sys/databricks/libs)
- **adfName** - Target Azure Data Factory of the deployment
- **apiBaseUrl** - Base API url (ei. [https://data.melbourne.vic.gov.au/resource/](https://data.melbourne.vic.gov.au/resource/))

#### Secure Variables

These are best stored within KeyVault, then [exposed via a Variable Group](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml#link-secrets-from-an-azure-key-vault).

- **sqlsrvrName** - Target SQL server name
- **sqlsrvUsername** - Target SQL server username
- **sqlsrvrPassword** - Target SQL server password
- **sqldwDatabaseName** - Target Synapse SQL Pool (formerly SQLDW) database name
- **databricksDomain** - Target Databricks workspace name (ei. [https://adb-123456789.1.azuredatabricks.net/](https://adb-123456789.1.azuredatabricks.net/))
- **databricksToken** - PAT token of the target databricks workspace
- **datalakeAccountName** - Target ADLS Gen2 storage account name
- **datalakeKey** - Key of target ADLS Gen2 storage
- **kvUrl** - KeyVault URL
- **spAdfId** - Service Principal Id used to run Data Factory Integration tests
- **spAdfPass** - Service Principal password used to run Data Factory Integration tests
- **spAdfTenantId** - Service Principal tenant Id used to run Data Factory Integration tests
- **subscriptionId** - Azure Subscription Id

## Require Service Connections

The following are [service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) that need to be in place.

- github_service_connection - used to checkout a pipeline resource (adf_publish).
- azure_service_connection_dev - used to in the release pipeline to deploy to **dev** azure environment.
- azure_service_connection_stg - used to in the release pipeline to deploy to **stg** azure environment.
- azure_service_connection_prod - used to in the release pipeline to deploy to **prod** azure environment.
