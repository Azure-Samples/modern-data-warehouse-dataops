param project string
param location string = resourceGroup().location
param deployment_id string

// Data Lake Storage
resource dataLakeStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${project}st1${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Data Lake Storage'
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

  resource dataLakeStorageFileSystem 'blobServices@2021-09-01' = {
    name: 'default'
    properties: {
      isVersioningEnabled: false
    }

    resource dataLakeStorageFileSystem2  'containers@2021-09-01' = {
      name: 'datalake'
      properties: {
        publicAccess: 'None'
      }
    }

    resource dataLakeStorageFileSystem3  'containers@2021-09-01' = {
      name: 'config'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// Synapse Storage
resource synapseStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${project}st2${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Synapse Storage'
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

  resource synapseStorageFileSystem 'blobServices@2021-09-01' = {
    name: 'default'
    properties: {
      isVersioningEnabled: false
    }

    resource synapseStorageFileSystem2  'containers@2021-09-01' = {
      name: 'synapsedefaults'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

output storage_account_name string = dataLakeStorage.name
output storage_account_name_synapse string = synapseStorage.name
