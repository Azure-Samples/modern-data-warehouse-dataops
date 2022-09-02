param project string
param location string = resourceGroup().location
param deployment_id string

param synStorageAccount string = '${project}st1${deployment_id}'
param mainStorageAccount string = '${project}st2${deployment_id}'
param synStorageFileSys string = 'synapsedefaults'

//https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var storage_blob_data_contributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource synStorage 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: synStorageAccount
}

resource synFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' existing = {
  name: synStorageFileSys
}

resource mainStorage 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: mainStorageAccount
}

resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-03-01' = {
  name: 'syws${deployment_id}'
  tags: {
    DisplayName: 'Synapse Workspace'
  }
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${synStorage.name}.dfs.${environment().suffixes.storage}'
      filesystem: synFileSystem.name
    }
    publicNetworkAccess: 'Enabled'
    managedResourceGroupName: '${project}-syn-mrg-${deployment_id}'
  }
}

resource synapseWorkspaceFirewallRule1 'Microsoft.Synapse/workspaces/firewallrules@2021-03-01' = {
  parent: synapseWorkspace
  name: 'allowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource roleAssignmentSynStorage1 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, resourceId('Microsoft.Storage/storageAccounts', synStorage.name))
  properties: {
    principalId: synapseWorkspace.identity.principalId
    roleDefinitionId: storage_blob_data_contributor
    principalType: 'ServicePrincipal'
  }
  scope: synStorage
}

resource roleAssignmentSynStorage2 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, resourceId('Microsoft.Storage/storageAccounts', mainStorage.name))
  properties: {
    principalId: synapseWorkspace.identity.principalId
    roleDefinitionId: storage_blob_data_contributor
    principalType: 'ServicePrincipal'
  }
  scope: mainStorage
}

output synapseWorkspaceName string = synapseWorkspace.name
output synapseDefaultStorageAccountName string = synStorage.name



