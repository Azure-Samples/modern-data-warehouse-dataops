param baseName string
param location string

@allowed([
  'F2'
  'F4'
  'F8'
  'F16'
  'F32'
  'F64'
  'F128'
  'F256'
  'F512'
  'F1024'
  'F2048'
])
param sku string
param adminEmail string

#disable-next-line BCP081
resource fabric_capacity 'Microsoft.Fabric/capacities@2022-07-01-preview' = {
  name: baseName
  location: location
  sku: {
    name: sku
    tier: 'Fabric'
  }
  properties: {
    administration: {
      members: [
        adminEmail
      ]
    }
  }
}

output capacityId string = fabric_capacity.id
output capacityName string = fabric_capacity.name
