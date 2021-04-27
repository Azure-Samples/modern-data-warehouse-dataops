output "kv_id" {
  value       = azurerm_key_vault.keyvault.id
  description = "Key vault id to be used for ADF linked service."
  sensitive   = true

}

output "kv_name" {
  value       = azurerm_key_vault.keyvault.name
  description = "Key vault name to be used for ADF linked service."
  sensitive   = true

}

output "kv_uri" {
  value       = azurerm_key_vault.keyvault.vault_uri
  description = "Key vault endpoint uri"
}
