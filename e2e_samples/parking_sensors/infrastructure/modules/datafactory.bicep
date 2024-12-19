//https://learn.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories
// Parameters
@description('The project name.')
param project string
@description('The environment for the deployment.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
@description('The location of the resource.')
param location string = resourceGroup().location
@description('The unique identifier for this deployment.')
param deployment_id string
// Data Factory Resource
resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${project}-adf-${env}-${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Data Factory'
    Environment: env
  }
  identity: {
    type: 'SystemAssigned'
  }
}
// Outputs
@description('The principal ID of the Data Factory identity.')
output datafactory_principal_id string = datafactory.identity.principalId
output datafactory_id string = datafactory.id
@description('The name of the Data Factory.')
output datafactory_name string = datafactory.name
