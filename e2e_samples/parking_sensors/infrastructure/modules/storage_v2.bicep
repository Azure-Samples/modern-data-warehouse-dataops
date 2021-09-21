param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param location string = resourceGroup().location
param deployment_id string
param contributor_principal_id string

//https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var storage_blob_data_contributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// Data Lake Storage
resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
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
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storage_roleassignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(storage.id)
  scope: storage
  properties: {
    roleDefinitionId: storage_blob_data_contributor
    principalId: contributor_principal_id
  }
}

// Synapse Storage
resource storage2 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: '${project}st2${env}${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Synapse Storage'
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
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageFileSystem2 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${project}st2${env}${deployment_id}/default/container001'
  properties: {
    publicAccess: 'Container'
  }
  dependsOn: [
    storage2
  ]
}

resource storage_roleassignment2 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(storage2.id)
  scope: storage2
  properties: {
    roleDefinitionId: storage_blob_data_contributor
    principalId: contributor_principal_id
  }
}

output storage_account_name string = storage.name
output storage_account_name_synapse string = storage2.name
