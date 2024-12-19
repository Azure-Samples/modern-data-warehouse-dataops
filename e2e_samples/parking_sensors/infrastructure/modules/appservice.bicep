@description('Name of the App Service')
param appName string

@description('SKU for the App Service Plan')
@allowed([
  'F1' // Free Tier
  'B1' // Basic Tier
])
param skuName string = 'B1'

@description('Region to deploy resources')
param location string = resourceGroup().location

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${appName}-plan'
  location: location
  sku: {
    name: skuName
    capacity: 1
  }
  properties: {
    reserved: false
  }
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}

output appServiceUrl string = appService.properties.defaultHostName
