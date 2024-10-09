param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param location string = resourceGroup().location
param deployment_id string
param datafactory_name string
param action_group_id string

resource adpipelinefailed 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${project}-adffailedalert-${env}-${deployment_id}'
  location: 'global'
  tags: {
    DisplayName: 'ADF Pipeline Failed'
    Environment: env
  }
  properties: {
    actions: [
      {
        actionGroupId: action_group_id        
      }
    ]
    autoMitigate: false
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
            threshold : 1
            name : 'Metric1'
            metricNamespace: 'Microsoft.DataFactory/factories'
            metricName: 'PipelineFailedRuns'
            operator: 'GreaterThan'
            timeAggregation: 'Total'
            criterionType: 'StaticThresholdCriterion'
        }
       ]      
    }
    description: 'ADF pipeline failed'
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DataFactory/factories/${datafactory_name}'
    ]
    severity: 1
    targetResourceRegion: location
    targetResourceType: 'Microsoft.DataFactory/factories'
    windowSize: 'PT5M'
  }
}
