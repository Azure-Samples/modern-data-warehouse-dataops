//https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers// Parameters
@description('The project name.')
param project string
@description('The environment for the deployment.')
param env string
@description('The location of the resource.')
param location string = resourceGroup().location
@description('The unique identifier for this deployment.')
param deployment_id string
@description('The username for the SQL Server.')
param sql_server_username string = 'sqlAdmin'
@secure()
@description('The password for the SQL Server.')
param sql_server_password string
@description('The login for the Entra admin.')
param entra_admin_login string
@description('The object ID of the Key Vault owner.')
param keyvault_owner_object_id string
@description('The tenant ID.')
param tenant_id string
// SQL Server Resource
resource sql_server 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: '${project}-sql-${env}-${deployment_id}'
  location: location
  tags: {
    DisplayName: 'SQL Server'
    Environment: env
  }
  properties: {
    administratorLogin: sql_server_username
    administratorLoginPassword: sql_server_password
    minimalTlsVersion: '1.2' 
    version: '12.0' // Specify SQL Server version
  }
  // Synapse Dedicated SQL Pool Resource
  resource synapse_dedicated_sql_pool 'databases@2023-05-01-preview' = {
    name: '${project}-syndp-${env}-${deployment_id}'
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
  // SQL Server Administrator Resource
  resource sql_server_admin 'administrators@2023-05-01-preview' = {
    name: 'ActiveDirectory'
    properties: {
      administratorType: 'ActiveDirectory'
      login: entra_admin_login
      sid: keyvault_owner_object_id
      tenantId: tenant_id
    }
  }
  // SQL Server Entra Only Authentication Resource
  resource sql_server_entra_only_auth 'azureADOnlyAuthentications@2023-05-01-preview' = {
    name: 'default'
    dependsOn: [
      sql_server_admin
    ]
    properties: {
      azureADOnlyAuthentication: false
    }
  }
  // Firewall Rules Resource
  resource firewall_rules 'firewallRules@2021-02-01-preview' = {
    name: 'AllowAllAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}
// Outputs
@description('Synapse SQL Pool Output.')
output synapse_sql_pool_output object = {
  name: sql_server.name
  username: sql_server_username
  synapse_pool_name: sql_server::synapse_dedicated_sql_pool.name
}
