output "databricks_workspace_host_url" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}

output "databricks_workspace_name" {
  value = azurerm_databricks_workspace.this.name
}

output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "databricks_workspace_id" {
  value = azurerm_databricks_workspace.this.workspace_id
}