output "workspace_name" {
  value = module.fabric_workspace.workspace_name
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

# output "security_group_id" {
#   value = azuread_group.sg.id
# }

# output "security_group_display_name" {
#   value = azuread_group.sg.display_name
# }

# output "storage_account_id" {
#   value = module.adls.storage_account_id
# }

# output "storage_account_name" {
#   value = module.adls.storage_account_name
# }

# output "storage_account_key" {
#   value     = module.adls.primary_access_key
#   sensitive = true
# }

# output "keyvault_id" {
#   value = module.keyvault.keyvault_id
# }

# output "keyvault_name" {
#   value = module.keyvault.keyvault_name
# }

# output "keyvault_uri" {
#   value = module.keyvault.keyvault_uri
# }

# output "log_analytics_workspace_id" {
#   value = module.loganalytics.workspace_id
# }

# output "log_analytics_workspace_name" {
#   value = module.loganalytics.workspace_name
# }

# output "appinsights_instrumentation_key" {
#   value     = module.application_insights.instrumentation_key
#   sensitive = true
# }

# output "appinsights_connection_string" {
#   value     = module.application_insights.connection_string
#   sensitive = true
# }

# output "appinsights_app_id" {
#   value = module.application_insights.app_id
# }

# output "fabric_capacity_id" {
#   value = module.fabric_capacity.capacity_id
# }

# output "fabric_capacity_name" {
#   value = module.fabric_capacity.capacity_name
# }
