//https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/actiongroups
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
@description('The unique identifier for this deployment.')
param deployment_id string
@description('The email address for the alert action group.')
param email_id string
// Resource: Action Group
resource actiongroup 'Microsoft.Insights/actionGroups@2024-10-01-preview' = {
  name: '${project}-emailactiongroup-${env}-${deployment_id}'
  location: 'global'
  tags: {
    DisplayName: 'Action Group'
    Environment: env
    Project: project
    DeploymentId: deployment_id
  }
  identity: {
    type: 'SystemAssigned' // Optional: Adjust based on your managed identity requirements
  }
  properties: {
    groupShortName: 'emailgroup'
    emailReceivers: [
      {
        emailAddress: email_id
        name: 'emailaction'
        useCommonAlertSchema: true
      }
    ]
    enabled: true
    // Additional receivers can be added here if needed
  }
}
// Outputs
@description('The ID of the created action group.')
output actiongroup_id string = actiongroup.id
