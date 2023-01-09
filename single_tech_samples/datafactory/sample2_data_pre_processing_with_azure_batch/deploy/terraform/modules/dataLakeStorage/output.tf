output "storage_account_id" {
  value = azurerm_storage_account.storage_account.id 
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_primary_dfs_url" {
  value = azurerm_storage_account.storage_account.primary_dfs_endpoint
}

output "storage_container_name" {
  value = azurerm_resource_group_template_deployment.storage-containers.name
}