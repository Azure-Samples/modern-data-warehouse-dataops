param project string
param location string = resourceGroup().location
param deployment_id string
param keyvault_owner_object_id string
param synapse_managed_identity string

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: '${project}kv${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Keyvault'
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: keyvault_owner_object_id
        permissions: {
            keys: [
                'all'
            ]
            secrets: [
                'all'
            ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: synapse_managed_identity
        permissions: {
            secrets: [
              'get'
              'list'
            ]
        }
      }
    ]
  }
}

output keyvault_name string = keyvault.name
