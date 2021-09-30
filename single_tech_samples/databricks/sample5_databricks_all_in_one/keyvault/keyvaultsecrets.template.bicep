param keyVaultName string
param LogAWkspId string

@secure()
param LogAWkspkey string
@secure()
param StorageAccountKey1 string
@secure()
param StorageAccountKey2 string
@secure()
param EventHubPK string
@secure()
param DbPATKey string

param updateAKVKeys bool

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultAddSecretsLogAWkspId 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if(updateAKVKeys) {
  parent: keyVault
  name: 'LogAWkspId'
  properties: {
    contentType: 'text/plain'
    value: LogAWkspId
  }
}
resource keyVaultAddSecretsLogAWkspkey 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if(updateAKVKeys)  {
  parent: keyVault
  name: 'LogAWkspkey'
  properties: {
    contentType: 'text/plain'
    value: LogAWkspkey
  }
}
resource keyVaultAddSecretsStg1 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if(updateAKVKeys) {
  parent: keyVault
  name: 'StorageAccountKey1'
  properties: {
    contentType: 'text/plain'
    value: StorageAccountKey1
  }
}
resource keyVaultAddSecretsStg2 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if(updateAKVKeys) {
  parent: keyVault
  name: 'StorageAccountKey2'
  properties: {
    contentType: 'text/plain'
    value: StorageAccountKey2
  }
}
resource keyVaultAddSecretsEventHubPK 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if(updateAKVKeys) {
  parent: keyVault
  name: 'EventHubPK'
  properties: {
    contentType: 'text/plain'
    value: EventHubPK
  }
}
resource keyVaultAddSecretsDatabricksPAT 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if(updateAKVKeys) {
  parent: keyVault
  name: 'DbPATKey'
  properties: {
    contentType: 'text/plain'
    value: DbPATKey
  }
}
