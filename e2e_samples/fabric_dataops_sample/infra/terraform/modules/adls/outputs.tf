output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "primary_access_key" {
  value = azurerm_storage_account.storage.primary_access_key
}

output "primary_dfs_endpoint" {
  value = azurerm_storage_account.storage.primary_dfs_endpoint
}

output "storage_container_name" {
  value = azurerm_storage_container.container.name
}
