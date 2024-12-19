//https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components
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
// Resource: Application Insights
resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${project}-appi-${env}-${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Application Insights'
    Environment: env
    Project: project
    DeploymentId: deployment_id
  }
  kind: 'other'
  properties: {
    Application_Type: 'other'
  }
}
// Output: Application Insights Name
@description('The name of the created Application Insights resource.')
output appinsights_name string = appinsights.name
