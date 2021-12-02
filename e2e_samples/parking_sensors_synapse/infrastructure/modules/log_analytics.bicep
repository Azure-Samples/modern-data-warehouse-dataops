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

<<<<<<< HEAD
=======
resource workspaceName_customEvents_event_handler 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  name: '${loganalyticsworkspace.name}/CustomEvents'
  properties: {
    etag: '*'
    displayName: 'Custom Events Parking Sensor - Events'
    category: 'Synapse Logging'
    query: 'SparkLoggingEvent_CL \r\n| where logger_name_s == "ParkingSensorLogs-Standardize" \r\n| order by TimeGenerated desc' 
    version: 1
  }
}

>>>>>>> f06c799 (fix(parking_sensors_synapse): clarity in README in parking sensor synapse sample, add requirement for Synapse extension, comment out debugging in script by default, add general troubleshooting section (#466))
output loganalyticswsname string = loganalyticsworkspace.name
