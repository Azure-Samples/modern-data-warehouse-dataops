@description('The environment for the deployment.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
@description('The location of the resource.')
param location string
@description('The name of the FunctionApp.')
param functionAppName string
@description('The name of Team for tagging purposes.')
param TeamName string
@description('The name of the storage account.')
param storageAccountName string
@description('The version of the node runtime.')
param linuxFxVersion string = 'node|22-lts'
@description('The name given to the hosting plan.')
param hostingPlanName string
@description('The site config always on setting.')
param alwaysOn bool = false

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' existing = {
  name: hostingPlanName
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  tags: {
    TeamName: TeamName
    Environment: env
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      alwaysOn: alwaysOn
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '22.14.0'
        }
        // {
        //   name: 'WEBSITE_RUN_FROM_PACKAGE'
        //   value: '<zip uri, e.g. blob storage uri>'
        // }
      ]
      cors: {
        allowedOrigins: [
          'https://ms.portal.azure.com'
        ]
      }
      nodeVersion: '22.14.0'
      linuxFxVersion: linuxFxVersion
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
  }
}

resource ftpPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: functionApp
  name: 'ftp'
  properties: {
    allow: false
  }
}

output functionapp_name string = functionApp.name
