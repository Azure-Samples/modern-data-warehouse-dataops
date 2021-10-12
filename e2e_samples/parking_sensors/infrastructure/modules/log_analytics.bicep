param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param location string = resourceGroup().location
param deployment_id string
param retentionInDays int = 31


resource loganalyticsworkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: '${project}-log-${env}-${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Log Analytics'
    Environment: env
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
      legacy: 0
    }
  }
}

resource workspaceName_customEvents_event_handler 'Microsoft.OperationalInsights/workspaces/savedSearches@2015-03-20' = {
  name: '${loganalyticsworkspace.name}/CustomEvents'
  properties: {
    displayName: 'Custom Events Parking Sensor - Events'
    category: 'Synapse Logging'
    query: 'SparkLoggingEvent_CL \r\n| where logger_name_s == "ParkingSensorLogs-Standardize" \r\n| order by TimeGenerated desc' 
    version: 1
  }
}

output loganalyticswsname string = loganalyticsworkspace.name
