param name string
param env string

resource storageAccount 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: replace('st${name}${env}', '-', '')
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2020-08-01-preview' = {
  name: '${storageAccount.name}/default/bloboutput'
}

output account object = {
  accountName: storageAccount.name
  accountKey: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
}
