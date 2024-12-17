output "storage_account_name" {
  value = module.adls.storage_account_name
}

output "storage_account_primary_dfs_endpoint" {
  value = module.adls.primary_dfs_endpoint
}

output "storage_container_name" {
  value = module.adls.storage_container_name
}

output "keyvault_name" {
  value = module.keyvault.keyvault_name
}

output "keyvault_uri" {
  value = module.keyvault.keyvault_uri
}

output "log_analytics_workspace_name" {
  value = module.loganalytics.workspace_name
}

output "workspace_name" {
  value = module.fabric_workspace.workspace_name
}

output "workspace_id" {
  value = module.fabric_workspace.workspace_id
}

output "lakehouse_name" {
  value = module.fabric_lakehouse.lakehouse_name
}

output "lakehouse_id" {
  value = module.fabric_lakehouse.lakehouse_id
}

output "environment_name" {
  value = module.fabric_environment.environment_name
}

output "environment_id" {
  value = module.fabric_environment.environment_id
}

output "notebook_name" {
  value = module.fabric_notebook.notebook_name
}

output "notebook_id" {
  value = module.fabric_notebook.notebook_id
}

output "fabric_workspace_admin_sg_principal_id" {
  value = data.azuread_group.fabric_workspace_admin.object_id
}
