
# DevOps Pipelines

## Required Variables:
The following variables needs to be set in your Release Pipelines.

### Solution Specific Variables:
- devAdfName - Name of the of ADF instance which has Git integration enabled.

### Environment Specific Variables:
These variables are stored in Variables Groups.
- azureLocation
- rgName
- databricksClusterId
- databricksNotebookPath
- databricksDbfsLibPath
- adfName
- kvUrl
- sqlDwDatabaseName
- apiBaseUrl

#### From KeyVault
- sqlsrvrName
- sqlsrvrPassword
- sqlsrvUsername
- databricksDomain
- databricksToken
- datalakeKey
- datalakeAccountName

## Require Service Connections
- github_service_connection - used to checkout a pipeline resource (adf_publish).
- azure_service_connection_stg - used to in the release pipeline to deploy to **stg** azure environment.
- azure_service_connection_prod - used to in the release pipeline to deploy to **prod** azure environment.