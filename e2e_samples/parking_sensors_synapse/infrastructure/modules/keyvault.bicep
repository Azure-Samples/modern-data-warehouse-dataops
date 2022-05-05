param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param location string = resourceGroup().location
param deployment_id string

param keyvault_owner_object_id string


resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: '${project}-kv-${env}-${deployment_id}'
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
    ]
  }
}

output keyvault_name string = keyvault.name
output keyvault_resource_id string = keyvault.id
