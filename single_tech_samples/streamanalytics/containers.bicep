param name string
param env string
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: replace('st${name}${env}', '-', '')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  resource blobServices 'blobServices' = {
    name: 'default'
    resource blobContainer 'containers' = {
      name: 'bloboutput'
    }    
  }
}

output storageAccountName string = storageAccount.name
