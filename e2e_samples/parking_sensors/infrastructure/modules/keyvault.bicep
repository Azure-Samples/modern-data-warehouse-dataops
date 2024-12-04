param env string
param location string = resourceGroup().location

param keyvault_name string
param keyvault_owner_object_id string
param datafactory_principal_id string
param enable_soft_delete bool = true
param enable_purge_protection bool = true


resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyvault_name
  location: location
  tags: {
    DisplayName: 'Keyvault'
    Environment: env
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableSoftDelete: enable_soft_delete
    enablePurgeProtection: enable_soft_delete && enable_purge_protection ? true : null
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
          objectId: datafactory_principal_id
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
output keyvault_resource_id string = keyvault.id
