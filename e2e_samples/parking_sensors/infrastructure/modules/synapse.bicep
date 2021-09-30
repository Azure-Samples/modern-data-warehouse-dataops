param project string
param env string
param location string = resourceGroup().location
param deployment_id string

param synStorageAccount string = '${project}st2${env}${deployment_id}'
param mainStorageAccount string = '${project}st${env}${deployment_id}'
param synStorageFileSys string = '${synStorageAccount}/default/container001'
param keyvault string = '${project}-kv-${env}-${deployment_id}'

param sql_server_username string = 'sqlAdmin'
@secure()
param sql_server_password string

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

resource sql_server 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: 'sql${env}${deployment_id}'
  location: location
  tags: {
    DisplayName: 'SQL Server'
    Environment: env
  }
  properties: {
    administratorLogin: sql_server_username
    administratorLoginPassword: sql_server_password
  }
  
  resource synapse_dedicated_sql_pool 'databases@2021-02-01-preview' = {
    name: 'syndp${env}${deployment_id}'
    location: location
    tags: {
      DisplayName: 'SQL Dedicated Pool'
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

  resource firewall_rules 'firewallRules@2021-02-01-preview' = {
    name: 'AllowAllAzureIps'
    properties: {
      endIpAddress: '0.0.0.0'
      startIpAddress: '0.0.0.0'
    }
  }
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
    managedVirtualNetwork: 'default'
    managedResourceGroupName: '${project}-mrg-${env}-syn'
    sqlAdministratorLogin: 'sqladminuser'
    sqlAdministratorLoginPassword: ''
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
output synapse_sql_pool_output object = {
  name: sql_server.name
  username: sql_server_username
  password: sql_server_password
  synapse_pool_name: sql_server::synapse_dedicated_sql_pool.name
}
output synapseBigdataPoolName string = synapse_spark_sql_pool.name
