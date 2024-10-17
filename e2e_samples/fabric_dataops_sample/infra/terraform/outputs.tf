output "workspace_name" {
  value = module.fabric_workspace.workspace_name
}

output "workspace_id" {
  value = module.fabric_workspace.workspace_id
}

output "lakehouse_id" {
  value = module.fabric_lakehouse.lakehouse_id
}

output "environment_name" {
  value = module.fabric_environment.environment_name
}

output "storage_container_name" {
  value = module.adls.storage_container_name
}

output "storage_account_primary_dfs_endpoint" {
  value = module.adls.primary_dfs_endpoint
}