//https://learn.microsoft.com/en-us/azure/templates/microsoft.databricks/workspaces
//https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments
//Parameters
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
@description('The principal ID of the contributor.')
param contributor_principal_id string
// Variables
@description('Role definition ID for Contributor.')
var contributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
// Databricks Workspace Resource
resource databricks 'Microsoft.Databricks/workspaces@2024-09-01-preview' = {
  name: '${project}-dbw-${env}-${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Databricks Workspace'
    Environment: env
  }
  sku: {
    name: 'premium'
    tier: 'Premium'
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', '${project}-${deployment_id}-dbw-${env}-rg')
  }
}
// Role Assignment Resource
resource databricks_roleassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(databricks.id)
  scope: databricks
  properties: {
    roleDefinitionId: contributor
    principalId: contributor_principal_id
    principalType: 'ServicePrincipal'
    description: 'Contributor access for Databricks workspace.'
  }
}
// Outputs
@description('Databricks workspace details.')
output databricks_output object = databricks
@description('Databricks workspace ID.')
output databricks_id string = databricks.id
@description('Databricks workspace URL.')
output databricks_workspace_url string = databricks.properties.workspaceUrl
