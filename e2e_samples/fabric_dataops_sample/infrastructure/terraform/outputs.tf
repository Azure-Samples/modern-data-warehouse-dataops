output "storage_account_id" {
  value = module.adls.storage_account_id
}

output "storage_account_name" {
  value = module.adls.storage_account_name
}

output "storage_account_primary_dfs_endpoint" {
  value = module.adls.primary_dfs_endpoint
}

output "storage_container_name" {
  value = module.adls.storage_container_name
}

output "keyvault_id" {
  value = module.keyvault.keyvault_id
}

output "keyvault_name" {
  value = module.keyvault.keyvault_name
}

output "keyvault_uri" {
  value = module.keyvault.keyvault_uri
}

output "log_analytics_workspace_id" {
  value = module.loganalytics.workspace_id
}

output "log_analytics_workspace_name" {
  value = module.loganalytics.workspace_name
}

output "appinsights_id" {
  value = module.appinsights.id
}

output "appinsights_name" {
  value = module.appinsights.name
}

output "appinsights_instrumentation_key" {
  value     = module.appinsights.instrumentation_key
  sensitive = true
}

output "appinsights_connection_string" {
  value     = module.appinsights.connection_string
  sensitive = true
}

output "workspace_name" {
  value = module.fabric_workspace.workspace_name
}

output "workspace_id" {
  value = module.fabric_workspace.workspace_id
}

output "lakehouse_name" {
  value = local.fabric_lakehouse_name
}

output "lakehouse_id" {
  value = var.deploy_fabric_items ? module.fabric_lakehouse.lakehouse_id : ""
}

output "environment_name" {
  value = local.fabric_environment_name
}

output "environment_id" {
  value = var.deploy_fabric_items ? module.fabric_environment.environment_id : ""
}

output "setup_notebook_name" {
  value = local.fabric_setup_notebook_name
}

output "setup_notebook_id" {
  value = var.deploy_fabric_items ? module.fabric_setup_notebook.notebook_id : ""
}

output "standardize_notebook_name" {
  value = local.fabric_standardize_notebook_name
}

output "standardize_notebook_id" {
  value = var.deploy_fabric_items ? module.fabric_standardize_notebook.notebook_id : ""
}

output "transform_notebook_name" {
  value = local.fabric_transform_notebook_name
}

output "transform_notebook_id" {
  value = var.deploy_fabric_items ? module.fabric_transform_notebook.notebook_id : ""
}

output "main_pipeline_name" {
  value = local.fabric_main_pipeline_name
}

output "main_pipeline_id" {
  value = var.deploy_fabric_items ? module.fabric_data_pipeline.data_pipeline_id : ""
}

output "fabric_workspace_admin_sg_principal_id" {
  value = data.azuread_group.fabric_workspace_admin.object_id
}

output "azdo_variable_group_name" {
  value = module.azure_devops_variable_group.variable_group_name
}

output "azdo_variable_group_kv_name" {
  value = module.azure_devops_variable_group_w_keyvault.variable_group_name
}

output "azdo_service_connection_name" {
  value = module.azure_devops_service_connection_azurerm.service_endpoint_name
}
