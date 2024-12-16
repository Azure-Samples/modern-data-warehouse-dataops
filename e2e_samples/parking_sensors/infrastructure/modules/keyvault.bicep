//https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
// Parameters
@description('The environment for the deployment.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
@description('The location of the resource.')
param location string = resourceGroup().location
@description('The Key Vault name.')
param keyvault_name string
@description('The object ID of the Key Vault owner.')
param keyvault_owner_object_id string
@description('The principal ID of the Data Factory.')
param datafactory_principal_id string
@description('Enable soft delete for the Key Vault.')
param enable_soft_delete bool = true
@description('Enable purge protection for the Key Vault.')
param enable_purge_protection bool = true
// Key Vault Resource
resource keyvault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
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
// Outputs
@description('The name of the Key Vault.')
output keyvault_name string = keyvault.name
@description('The resource ID of the Key Vault.')
output keyvault_resource_id string = keyvault.id
