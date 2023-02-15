param project string
param env string
param deployment_id string
param loganalytics_workspace_name string
param datafactory_name string

var commonPrefix = '${project}-diag-${env}-${deployment_id}'

resource datafactoryworkspace 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactory_name
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: loganalytics_workspace_name
}

resource diagnosticSetting1 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: datafactoryworkspace
  name: '${commonPrefix}-${datafactoryworkspace.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
        enabled: true
      }
      {
        category: 'ActivityRuns'
        enabled: true
      }      
    ]    
    metrics: [
      {
      category: 'AllMetrics'
      enabled: true
      }
    ]
  }
}
