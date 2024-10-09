output "adls_account_id" {
  value = azurerm_storage_account.adls.id 
}

output "adls_account_name" {
  value = azurerm_storage_account.adls.name
}

output "adls_account_primary_dfs_url" {
  value = azurerm_storage_account.adls.primary_dfs_endpoint
}

output "adls_container_name" {
  value = azurerm_resource_group_template_deployment.storage-containers.name
}