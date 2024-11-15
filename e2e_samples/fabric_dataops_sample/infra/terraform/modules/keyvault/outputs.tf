output "keyvault_id" {
  value = azurerm_key_vault.keyvault.id
}

output "keyvault_name" {
  value = azurerm_key_vault.keyvault
}

output "keyvault_uri" {
  value = azurerm_key_vault.keyvault.vault_uri
}
