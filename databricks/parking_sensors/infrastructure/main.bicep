/* Partner attribution resource for telemetry. For usage details, see https://github.com/microsoft/modern-data-warehouse-dataops/blob/main/README.md#data-collection */
resource attribution 'Microsoft.Resources/deployments@2020-06-01' = {
  name: 'pid-acce1e78-babd-6b30-049f-9496f0518a8f'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

param project string = 'mdwdo'
param env string = 'dev'
param email_id string = 'support@domain.com'
param location string = resourceGroup().location
param deployment_id string
param keyvault_owner_object_id string
@secure()
param sql_server_password string
param enable_monitoring bool
param keyvault_name string
param enable_keyvault_soft_delete bool = true
param enable_keyvault_purge_protection bool = true
param entra_admin_login string

module appservice './modules/appservice.bicep' = {
  name: 'appservices_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
  }
}

module datafactory './modules/datafactory.bicep' = {
  name: 'datafactory_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
  }
}

module databricks './modules/databricks.bicep' = {
  name: 'databricks_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    contributor_principal_id: datafactory.outputs.datafactory_principal_id
  }
}

module storage './modules/storage.bicep' = {
  name: 'storage_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    contributor_principal_id: datafactory.outputs.datafactory_principal_id
  }
}

module synapse_sql_pool './modules/synapse_sql_pool.bicep' = {
  name: 'synapse_sql_pool_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    sql_server_password: sql_server_password
    entra_admin_login: entra_admin_login
    keyvault_owner_object_id: keyvault_owner_object_id
    tenant_id: subscription().tenantId
  }
}

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault_deploy_${deployment_id}'
  params: {
    keyvault_name: keyvault_name
    env: env
    location: location
    enable_soft_delete: enable_keyvault_soft_delete
    enable_purge_protection: enable_keyvault_purge_protection
    keyvault_owner_object_id: keyvault_owner_object_id
    datafactory_principal_id: datafactory.outputs.datafactory_principal_id
  }
}


module appinsights './modules/appinsights.bicep' = {
  name: 'appinsights_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
  }
}

module loganalytics './modules/log_analytics.bicep' = if (enable_monitoring) {
  name: 'log_analytics_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
  }
}


module diagnostic './modules/diagnostic_settings.bicep' = if (enable_monitoring) {
  name: 'diagnostic_settings_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    deployment_id: deployment_id
    loganalytics_workspace_name: loganalytics.outputs.loganalyticswsname
    datafactory_name: datafactory.outputs.datafactory_name    
  }
}


module dashboard './modules/dashboard.bicep' = if (enable_monitoring) {
  name: 'dashboard_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    datafactory_name: datafactory.outputs.datafactory_name
    sql_server_name: synapse_sql_pool.outputs.synapse_sql_pool_output.name
    sql_database_name: synapse_sql_pool.outputs.synapse_sql_pool_output.synapse_pool_name
  }
}

module actiongroup './modules/actiongroup.bicep' = if (enable_monitoring) {
  name: 'actiongroup_${deployment_id}'
  params: {
    project: project
    env: env
    deployment_id: deployment_id
    email_id: email_id
  }
}

module alerts './modules/alerts.bicep' = if (enable_monitoring) {
  name: 'alerts_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    datafactory_name: datafactory.outputs.datafactory_name
    action_group_id: actiongroup.outputs.actiongroup_id
  }
  dependsOn: [
    loganalytics
  ]
}

module data_quality_workbook './modules/data_quality_workbook.bicep' = if (enable_monitoring) {
  name: 'wb_${deployment_id}'
  params: {
    appinsights_name: appinsights.outputs.appinsights_name
    location: location
  }
  dependsOn: [
    loganalytics
  ]
}



output storage_account_name string = storage.outputs.storage_account_name
output synapse_sql_pool_output object = synapse_sql_pool.outputs.synapse_sql_pool_output
output databricks_output object = databricks.outputs.databricks_output
output databricks_id string = databricks.outputs.databricks_id
output appinsights_name string = appinsights.outputs.appinsights_name
output keyvault_name string = keyvault.outputs.keyvault_name
output keyvault_resource_id string = keyvault.outputs.keyvault_resource_id
output datafactory_id string = datafactory.outputs.datafactory_id
output datafactory_name string = datafactory.outputs.datafactory_name
output loganalytics_name string = loganalytics.outputs.loganalyticswsname
