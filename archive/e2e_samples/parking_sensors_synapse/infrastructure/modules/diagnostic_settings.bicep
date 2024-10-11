param project string
param env string
param deployment_id string
param loganalytics_workspace_name string
param synapse_workspace_name string
param synapse_sql_pool_name string
param synapse_spark_pool_name string

var commonPrefix = '${project}-diag-${env}-${deployment_id}'

resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-03-01' existing = {
  name: synapse_workspace_name
}

resource synapseSqlPool001 'Microsoft.Synapse/workspaces/sqlPools@2021-03-01' existing = {
  parent: synapseWorkspace
  name: synapse_sql_pool_name
}

resource synapseBigDataPool001 'Microsoft.Synapse/workspaces/bigDataPools@2021-03-01' existing = {
  parent: synapseWorkspace
  name: synapse_spark_pool_name
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: loganalytics_workspace_name
}

resource diagnosticSetting1 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: synapseWorkspace
  name: '${commonPrefix}-${synapseWorkspace.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'SynapseRbacOperations'
        enabled: true
      }
      {
        category: 'GatewayApiRequests'
        enabled: true
      }
      {
        category: 'BuiltinSqlReqsEnded'
        enabled: true
      }
      {
        category: 'IntegrationPipelineRuns'
        enabled: true
      }
      {
        category: 'IntegrationActivityRuns'
        enabled: true
      }
      {
        category: 'IntegrationTriggerRuns'
        enabled: true
      }
    ]
  }
}

resource diagnosticSetting2 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: synapseSqlPool001
  name: '${commonPrefix}-${synapseWorkspace.name}-${synapseSqlPool001.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'SqlRequests'
        enabled: true
      }
      {
        category: 'RequestSteps'
        enabled: true
      }
      {
        category: 'ExecRequests'
        enabled: true
      }
      {
        category: 'DmsWorkers'
        enabled: true
      }
      {
        category: 'Waits'
        enabled: true
      }
    ]
  }
}

resource diagnosticSetting3 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: synapseBigDataPool001
  name: '${commonPrefix}-${synapseWorkspace.name}-${synapseBigDataPool001.name}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'BigDataPoolAppsEnded'
        enabled: true
      }
    ]
  }
}
