output "storage_account_id" {
  value = azurerm_storage_account.batch_storage.id
}

output "storage_account_name" {
  value = azurerm_storage_account.batch_storage.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.batch_storage.primary_blob_endpoint
}
