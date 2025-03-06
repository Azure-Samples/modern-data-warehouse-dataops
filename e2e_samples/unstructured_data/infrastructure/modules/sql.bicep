// https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers
// https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases
@description('The environment for the deployment.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the SQL logical server.')
param sql_server_name string

@description('The name of the SQL Database.')
param sql_db_name string

@description('The AAD group name granted admin access to the SQL Server.')
param aad_group_name string

@description('The AAD group object ID granted admin access to the SQL Server.')
param aad_group_object_id string

@description('IP address to whitelist.')
param ip_address string

resource sql_server 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sql_server_name
  location: location
  tags: {
    DisplayName: 'SQL Server'
    Environment: env
  }
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: aad_group_name
      sid: aad_group_object_id
      tenantId: subscription().tenantId
    }
  }
}

resource sql_db 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sql_server
  name: sql_db_name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource aad_auth 'Microsoft.Sql/servers/azureADOnlyAuthentications@2024-05-01-preview' = {
  name: 'Default'
  parent: sql_server
  properties: {
    azureADOnlyAuthentication: true
  }
}

// Firewall
resource db_firewall 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = {
  name: 'Database server firewall'
  parent: sql_server
  properties: {
    startIpAddress: ip_address
    endIpAddress: ip_address
  }
}

resource azure_fire_wall_rule 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = {
  parent: sql_server
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Outputs
@description('The name of the SQL Server.')
output sql_server_name string = sql_server.name
@description('The resource ID of the SQL Server.')
output sql_server_resource_id string = sql_server.id

@description('The name of the SQL Database.')
output sql_db_name string = sql_db.name
@description('The resource ID of the SQL Server.')
output sql_db_resource_id string = sql_db.id
