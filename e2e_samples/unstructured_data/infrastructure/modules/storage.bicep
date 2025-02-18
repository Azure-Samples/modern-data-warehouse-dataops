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

// Outputs
@description('The name of the storage account.')
output storage_account_name string = storage.name
