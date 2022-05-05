param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param location string = resourceGroup().location
param deployment_id string


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

// Synapse Storage
resource synapseStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
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

  resource synapseStorageFileSystem 'blobServices@2021-04-01' = {
    name: 'default'
    properties: {
      isVersioningEnabled: false
    }
    dependsOn: [
      synapseStorage
    ]

    resource synapseStorageFileSystem2  'containers@2021-04-01' = {
      name: 'synapsedefaultfs'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

output storage_account_name string = storage.name
output storage_account_name_synapse string = synapseStorage.name
