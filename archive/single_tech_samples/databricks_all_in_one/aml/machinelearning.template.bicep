param keyVaultIdentifierId string
param storageAccount string
param amlWorkspaceName string
param containerRegistryName string
param applicationInsightsName string
// param identity string
param aksClusterPrincipleId string
param aksAmlComputeName string
param aksClusterId string
param sslLeafName string
param linkAkstoAml bool
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRoleDefId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var location = resourceGroup().location

resource ctrRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    anonymousPullEnabled: false
    dataEndpointEnabled: true
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

resource aksRoleAssignmentToAcr 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: ctrRegistry
  name: aksClusterPrincipleId
  properties: {
    principalId: aksClusterPrincipleId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefId)
  }
}

resource applicationInsightsName_resource 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource aml 'Microsoft.MachineLearningServices/workspaces@2021-04-01' = {
  name: amlWorkspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: amlWorkspaceName
    storageAccount: storageAccount
    keyVault: keyVaultIdentifierId
    applicationInsights: applicationInsightsName_resource.id
    containerRegistry: ctrRegistry.id
    allowPublicAccessWhenBehindVnet: true
  }
}

resource standaloneAks 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = if (linkAkstoAml) {
  parent: aml
  name: aksAmlComputeName
  location: location
  properties: {
    computeType: 'AKS'
    computeLocation: location
    resourceId: aksClusterId
    description: 'External AKS cluster to provide inference REST endpoint'
    properties: {
      clusterPurpose: 'FastProd'
      sslConfiguration: {
        status: 'Auto'
        leafDomainLabel: sslLeafName
        overwriteExistingDomain: true
      }
    }
  }
}

output amlId string = aml.id
output amlWkspName string = amlWorkspaceName
output amlProperties object = aml.properties
output ctrRegistryName string = ctrRegistry.name
output ctrRegistryId string = ctrRegistry.id
