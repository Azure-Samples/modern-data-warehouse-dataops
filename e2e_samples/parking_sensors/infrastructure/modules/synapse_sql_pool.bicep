param project string
param env string
param location string = resourceGroup().location
param deployment_id string

param sql_server_username string = 'sqlAdmin'
@secure()
param sql_server_password string
param entra_admin_login string
param keyvault_owner_object_id string
param tenant_id string


resource sql_server 'Microsoft.Sql/servers@2023-08-01-preview' = {
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
}

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

  resource sql_server_admin 'administrators@2023-05-01-preview' = {
    name: 'ActiveDirectory'
    properties: {
      administratorType: 'ActiveDirectory'
      login: entra_admin_login
      sid: keyvault_owner_object_id
      tenantId: tenant_id
    }
  }

  resource sql_server_entra_only_auth 'azureADOnlyAuthentications@2023-05-01-preview' = {
    name: 'default'
    dependsOn: [
      sql_server_admin
    ]
    properties: {
      azureADOnlyAuthentication: false
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

output synapse_sql_pool_output object = {
  name: sql_server.name
  username: sql_server_username
  synapse_pool_name: sql_server::synapse_dedicated_sql_pool.name
}
