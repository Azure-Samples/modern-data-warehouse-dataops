@description('The environment for the deployment.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string

@description('The location of the resource.')
param location string = resourceGroup().location

@description('The name of the FunctionApp.')
param functionAppName string

@description('The name of Team for tagging purposes.')
param TeamName string

@description('The storage account key.')
@secure()
param storageAccountKey string

// param ftpsState string = 'FtpsOnly'
param storageAccountName string

param linuxFxVersion string = 'node|22-lts'
param hostingPlanId string
param alwaysOn bool = false

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  tags: {
    TeamName: TeamName
    Environment: env
  }
  properties: {
    serverFarmId: hostingPlanId
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
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
      // ftpsState: ftpsState
      linuxFxVersion: linuxFxVersion
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
  }
}

resource scmPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: functionApp
  name: 'scm'
  properties: {
    allow: false
  }
}

resource ftpPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: functionApp
  name: 'ftp'
  properties: {
    allow: false
  }
}
