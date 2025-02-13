param project string = 'unstructured_data'
param env string = 'dev'
// param email_id string = 'support@domain.com'
param location string = resourceGroup().location
param deployment_id string
param keyvault_owner_object_id string
// param enable_monitoring bool
param keyvault_name string
param enable_keyvault_soft_delete bool = true
param enable_keyvault_purge_protection bool = true
// param entra_admin_login string
param sql_server_name string
param sql_db_name string
param aad_group_name string
param aad_group_object_id string
param ip_address string
param team_name string

module databricks './modules/databricks.bicep' = {
  name: 'databricks_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    team_name: team_name
    // contributor_principal_id: datafactory.outputs.datafactory_principal_id
  }
}

module storage './modules/storage.bicep' = {
  name: 'storage_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    // contributor_principal_id: datafactory.outputs.datafactory_principal_id
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
    // datafactory_principal_id: datafactory.outputs.datafactory_principal_id
  }
}

module sql './modules/sql.bicep' = {
  name: 'sql_deploy_${deployment_id}'
  params: {
    sql_server_name: sql_server_name
    sql_db_name: sql_db_name
    env: env
    location: location
    aad_group_name: aad_group_name
    aad_group_object_id: aad_group_object_id
    ip_address: ip_address
  }
}

module appservice './modules/appservice.bicep' = {
  name: 'appservice_deploy_${deployment_id}'
  params: {
    env: env
    webAppName: 'excitation'
    hostingPlanName: 'excitation-testing'
    location: location
    sku: 'S1'
    tier: 'Standard'
    TeamName: team_name
  }
}

module functionapp './modules/functionapp.bicep' = {
  name: 'functionapp_deploy_${deployment_id}'
  params: {
    env: env
    functionAppName: 'excitationfuncapp'
    hostingPlanId: appservice.outputs.hostingPlanId
    storageAccountName: storage.outputs.storage_account_name
    storageAccountKey: storage.outputs.storage_account_key
    location: location
    TeamName: team_name
  }
}

// module appinsights './modules/appinsights.bicep' = {
//   name: 'appinsights_deploy_${deployment_id}'
//   params: {
//     project: project
//     env: env
//     location: location
//     deployment_id: deployment_id
//   }
// }

// module loganalytics './modules/log_analytics.bicep' = if (enable_monitoring) {
//   name: 'log_analytics_deploy_${deployment_id}'
//   params: {
//     project: project
//     env: env
//     location: location
//     deployment_id: deployment_id
//   }
// }

// module diagnostic './modules/diagnostic_settings.bicep' = if (enable_monitoring) {
//   name: 'diagnostic_settings_deploy_${deployment_id}'
//   params: {
//     project: project
//     env: env
//     deployment_id: deployment_id
//     loganalytics_workspace_name: loganalytics.outputs.loganalyticswsname
//     datafactory_name: datafactory.outputs.datafactory_name
//   }
// }

// module dashboard './modules/dashboard.bicep' = if (enable_monitoring) {
//   name: 'dashboard_${deployment_id}'
//   params: {
//     project: project
//     env: env
//     location: location
//     deployment_id: deployment_id
//     datafactory_name: datafactory.outputs.datafactory_name
//     sql_server_name: synapse_sql_pool.outputs.synapse_sql_pool_output.name
//     sql_database_name: synapse_sql_pool.outputs.synapse_sql_pool_output.synapse_pool_name
//   }
// }

// module actiongroup './modules/actiongroup.bicep' = if (enable_monitoring) {
//   name: 'actiongroup_${deployment_id}'
//   params: {
//     project: project
//     env: env
//     deployment_id: deployment_id
//     email_id: email_id
//   }
// }

// module alerts './modules/alerts.bicep' = if (enable_monitoring) {
//   name: 'alerts_${deployment_id}'
//   params: {
//     project: project
//     env: env
//     location: location
//     deployment_id: deployment_id
//     datafactory_name: datafactory.outputs.datafactory_name
//     action_group_id: actiongroup.outputs.actiongroup_id
//   }
//   dependsOn: [
//     loganalytics
//   ]
// }

// module data_quality_workbook './modules/data_quality_workbook.bicep' = if (enable_monitoring) {
//   name: 'wb_${deployment_id}'
//   params: {
//     appinsights_name: appinsights.outputs.appinsights_name
//     location: location
//   }
//   dependsOn: [
//     loganalytics
//   ]
// }

output storage_account_name string = storage.outputs.storage_account_name
output databricks_output object = databricks.outputs.databricks_output
output databricks_id string = databricks.outputs.databricks_id
// output appinsights_name string = appinsights.outputs.appinsights_name
output keyvault_name string = keyvault.outputs.keyvault_name
output keyvault_resource_id string = keyvault.outputs.keyvault_resource_id
// output loganalytics_name string = loganalytics.outputs.loganalyticswsname
output sql_server_name string = sql.outputs.sql_server_name
output sql_server_resource_id string = sql.outputs.sql_server_resource_id
output sql_db_name string = sql.outputs.sql_db_name
output sql_db_resource_id string = sql.outputs.sql_db_resource_id
