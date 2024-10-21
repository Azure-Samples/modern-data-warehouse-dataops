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

output "storage_account_name" {
  value = module.adls.storage_account_name
}

output "storage_account_location" {
  value = module.adls.storage_account_location
}

output "storage_container_name" {
  value = module.adls.storage_container_name
}

output "storage_account_primary_dfs_endpoint" {
  value = module.adls.primary_dfs_endpoint
}

output "notebook_001_id" {
  value = module.fabric_notebook_001.notebook_id
}

output "notebook_001_name" {
  value = module.fabric_notebook_001.notebook_name
}

output "notebook_002_id" {
  value = module.fabric_notebook_002.notebook_id
}

output "notebook_002_name" {
  value = module.fabric_notebook_002.notebook_name
}

output "data_pipeline_001_id" {
  value = module.fabric_data_pipeline_001.data_pipeline_id
}

output "data_pipeline_001_name" {
  value = module.fabric_data_pipeline_001.data_pipeline_name
}