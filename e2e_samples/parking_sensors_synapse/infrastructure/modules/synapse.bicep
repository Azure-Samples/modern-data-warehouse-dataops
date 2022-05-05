param project string
param env string
param location string = resourceGroup().location
param deployment_id string

param synStorageAccount string = '${project}st2${env}${deployment_id}'
param mainStorageAccount string = '${project}st${env}${deployment_id}'
param synStorageFileSys string = 'synapsedefaultfs'
param keyvault string = '${project}-kv-${env}-${deployment_id}'
param synapse_sqlpool_admin_username string = 'sqlAdmin'
@secure()
param synapse_sqlpool_admin_password string

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

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyvault
}

resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-03-01' = {
  name: 'syws${env}${deployment_id}'
  tags: {
    DisplayName: 'Synapse Workspace'
    Environment: env
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
    managedResourceGroupName: '${project}-syn-mrg-${env}-${deployment_id}'
    sqlAdministratorLogin: synapse_sqlpool_admin_username
    sqlAdministratorLoginPassword: synapse_sqlpool_admin_password
  }

  resource synapseFirewall 'firewallRules@2021-06-01-preview' = {
      name: 'AllowAllWindowsAzureIps'
      properties: {
        startIpAddress: '0.0.0.0'
        endIpAddress: '0.0.0.0'
      }
  }
}

resource synapse_spark_sql_pool 'Microsoft.Synapse/workspaces/bigDataPools@2021-03-01' = {
  parent: synapseWorkspace
  name: 'synsp${env}${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Spark SQL Pool'
    Environment: env
  }
  properties: {
    isComputeIsolationEnabled: false
    nodeSizeFamily: 'MemoryOptimized'
    nodeSize: 'Small'
    autoScale: {
      enabled: true
      minNodeCount: 3
      maxNodeCount: 10
    }
    dynamicExecutorAllocation: {
      enabled: false
    }
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    sparkVersion: '2.4'
    sessionLevelPackagesEnabled: true
    customLibraries: []
    defaultSparkLogFolder: 'logs/'
    sparkEventsFolder: 'events/'
  }
}

resource synapse_sql_pool 'Microsoft.Synapse/workspaces/sqlPools@2021-03-01' = {
  parent: synapseWorkspace
  name: 'syndp${env}${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Synapse Dedicated SQL Pool'
    Environment: env
  }
  sku: {
    name: 'DW100c'
    tier: 'DataWarehouse'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
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

resource kvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: kv
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: synapseWorkspace.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

output synapseWorkspaceName string = synapseWorkspace.name
output synapseDefaultStorageAccountName string = synStorage.name
output synapseBigdataPoolName string = synapse_spark_sql_pool.name
output synapse_sql_pool_output object = {
  username: synapseWorkspace.properties.sqlAdministratorLogin
  password: synapse_sqlpool_admin_password
  synapse_pool_name: synapse_sql_pool.name
}


