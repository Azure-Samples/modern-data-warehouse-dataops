//https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/metricalerts?pivots=deployment-language-bicep
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
@description('The name of the Data Factory.')
param datafactory_name string
@description('The ID of the action group.')
param action_group_id string
// Resource: Metric Alert
resource adpipelinefailed 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${project}-adffailedalert-${env}-${deployment_id}'
  location: 'global'
  tags: {
    DisplayName: 'ADF Pipeline Failed'
    Environment: env
    Project: project
    DeploymentId: deployment_id
  }
  properties: {
    description: 'ADF pipeline failed'
    enabled: true
    severity: 1
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    scopes: [
      '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DataFactory/factories/${datafactory_name}'
    ]
    targetResourceType: 'Microsoft.DataFactory/factories'
    targetResourceRegion: location
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'PipelineFailedRunsCriteria'
          metricName: 'PipelineFailedRuns'
          metricNamespace: 'Microsoft.DataFactory/factories'
          operator: 'GreaterThan'
          threshold: 1
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: action_group_id
        webHookProperties: {
          exampleProperty: 'exampleValue'
        }
      }
    ]
    autoMitigate: false
  }
}
// Outputs
@description('The ID of the created metric alert.')
output adpipelinefailed_id string = adpipelinefailed.id
