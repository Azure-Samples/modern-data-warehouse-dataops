resource "azurerm_key_vault_secret" "azure_batch_key" {
  name         = var.azure_batch_key_name
  value        = var.batch_key_secret
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "azure_batch_storage_key" {
  name         = var.azure_batch_storage_key_name
  value        = var.batch_storage_key_secret
  key_vault_id = var.key_vault_id
}
