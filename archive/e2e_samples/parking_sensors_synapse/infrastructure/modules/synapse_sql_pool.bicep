param project string
param env string
param location string = resourceGroup().location
param deployment_id string

param sql_server_username string = 'sqlAdmin'
@secure()
param sql_server_password string


resource sql_server 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: '${project}-sql-${env}-${deployment_id}'
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
  password: sql_server_password
  synapse_pool_name: sql_server::synapse_dedicated_sql_pool.name
}
