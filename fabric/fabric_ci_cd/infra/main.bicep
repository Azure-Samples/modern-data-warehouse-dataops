param location string = resourceGroup().location
param capacityName string
param adminEmail string
param sku string = 'F2'

/* Partner attribution resource for telemetry. For usage details, see https://github.com/microsoft/modern-data-warehouse-dataops/blob/main/README.md#data-collection */
resource attribution 'Microsoft.Resources/deployments@2020-06-01' = {
  name: 'pid-acce1e78-fc34-eddc-0120-b3e2262beff3'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

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
