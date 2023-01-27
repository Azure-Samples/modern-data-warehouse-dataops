output "storage_account_id" {
  value = azurerm_storage_account.batch_storage.id
}

output "storage_account_name" {
  value = azurerm_storage_account.batch_storage.name
}

output "storage_account_primary_access_key" {
  value = azurerm_storage_account.batch_storage.primary_access_key
}

output "storage_account_primary_connection_string" {
  value = azurerm_storage_account.batch_storage.primary_connection_string
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.batch_storage.primary_blob_endpoint
}
