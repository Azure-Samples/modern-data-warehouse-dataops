@description('Name of the App Service')
param project string
param location string
param deployment_id string

@description('SKU for the App Service Plan')
@allowed([
  'F1' // Free Tier
  'B1' // Basic Tier
])
param skuName string = 'B1'

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: '${project}-plan-${deployment_id}'
  location: location
  sku: {
    name: skuName
    capacity: 1
  }
  properties: {
    reserved: false
  }
}

resource appService 'Microsoft.Web/sites@2024-04-01' = {
  name: '${project}-api-${deployment_id}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18' // Specify the runtime stack here
        }
      ]
    }
  }
}

output appServiceUrl string = appService.properties.defaultHostName
