param location string = resourceGroup().location
param capacityName string
param adminEmail string
param sku string = 'F2'

module fab './fabric_capacity.bicep' = {
  name: 'deploy_capacity'
  params: {
    baseName: capacityName
    location: location
    sku: sku
    adminEmail: adminEmail
  }
}

output capacityName string = fab.outputs.capacityName
output capacityId string = fab.outputs.capacityId
