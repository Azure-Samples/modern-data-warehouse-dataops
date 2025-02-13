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
@description('The name of the web app.')
param webAppName string = 'excitation'

// @description('The URL of the repository.')
// param repoUrl string = 'https://github.com/Joll59/excitation'
// @description('The path of the repository.')
// param repoPath string = 'client'

@description('The name of the hosting plan.')
param hostingPlanName string
@description('The SKU of the hosting plan.')
param sku string
@description('The tier of the hosting plan.')
param tier string
@description('The name of Team for tagging purposes.')
param TeamName string

// app service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: hostingPlanName
  location: location
  tags: {
    DisplayName: '${webAppName}-AppServicePlan'
    Environment: env
    TeamName: TeamName
  }
  sku: {
    name: sku
    tier: tier
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// web app
resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  kind: 'app'
  tags: {
    DisplayName: '${webAppName}-App'
    Environment: env
    TeamName: TeamName
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      nodeVersion: '22.14.0'
      linuxFxVersion: 'NODE|22-lts'
      scmType: 'GitHub'
      appCommandLine: 'pm2 serve /home/site/wwwroot/dist --no-daemon --spa'
    }
    httpsOnly: true
  }
}

// potential source control configuration, currently not working as intended
// resource sourceControl 'Microsoft.Web/sites/sourcecontrols@2024-04-01' = {
//   parent: webApp
//   name: 'web'
//   properties: {
//     repoUrl: '${repoUrl}.git:${repoPath}'
//     branch: 'main'
//     isManualIntegration: true
//   }
// }

output hostingPlanId string = appServicePlan.id
