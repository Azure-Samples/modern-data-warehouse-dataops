output "key_vault_id" {
  description = "Key Vault identifier"
  value       = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  description = "Key vault name"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "the generated URI of key vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "object_id" {
  value = data.azurerm_client_config.current.object_id
}
