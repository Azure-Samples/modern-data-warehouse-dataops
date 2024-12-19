//https://learn.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories
//https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces
//https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
// Parameters
@description('The project name.')
param project string
@description('The environment for the deployment.')
param env string
@description('The unique identifier for this deployment.')
param deployment_id string
@description('The name of the Log Analytics workspace.')
param loganalytics_workspace_name string
@description('The name of the Data Factory.')
param datafactory_name string
// Variables
var commonPrefix = '${project}-diag-${env}-${deployment_id}'
// Existing Data Factory Resource
resource datafactoryworkspace 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactory_name
}
// Existing Log Analytics Workspace Resource
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: loganalytics_workspace_name
}
// Diagnostic Settings Resource
resource diagnosticSetting1 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: datafactoryworkspace
  name: '${commonPrefix}-${datafactoryworkspace.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'PipelineRuns'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'TriggerRuns'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'ActivityRuns'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }      
    ]    
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}
