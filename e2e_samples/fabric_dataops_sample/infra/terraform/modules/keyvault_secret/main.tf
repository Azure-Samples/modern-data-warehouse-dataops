resource "azurerm_key_vault_secret" "secret" {
  name         = var.name
  value        = var.value
  key_vault_id = var.key_vault_id
}