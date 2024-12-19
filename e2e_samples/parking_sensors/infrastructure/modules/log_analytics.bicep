//https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces
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
@description('The retention period for logs in days.')
param retentionInDays int = 31
// Log Analytics Workspace Resource
resource loganalyticsworkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${project}-log-${env}-${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Log Analytics'
    Environment: env
  }
  properties: {
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
      legacy: 0
    }
    sku: {
      name: 'PerGB2018'
    }
  }
}
// Outputs
@description('The name of the Log Analytics Workspace.')
output loganalyticswsname string = loganalyticsworkspace.name
