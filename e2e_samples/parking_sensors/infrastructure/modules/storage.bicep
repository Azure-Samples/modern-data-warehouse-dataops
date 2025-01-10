//https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
//https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments
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
@description('The principal ID of the contributor.')
param contributor_principal_id string
// Variables
@description('Role definition ID for Storage Blob Data Contributor.')
var storage_blob_data_contributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
// Storage Account Resource
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: '${project}st${env}${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Data Lake Storage'
    Environment: env
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
          keyType: 'Account'
        }
        blob: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}
// Role Assignment Resource
resource storage_roleassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id)
  scope: storage
  properties: {
    roleDefinitionId: storage_blob_data_contributor
    principalId: contributor_principal_id
    principalType: 'ServicePrincipal'
    description: 'Grants Storage Blob Data Contributor access to the service principal.'
  }
}
// Outputs
@description('The name of the storage account.')
output storage_account_name string = storage.name
