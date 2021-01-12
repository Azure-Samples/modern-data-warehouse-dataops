output "keyvault_id" {
  value       = azurerm_key_vault.kv.id
  description = "Specifies the name of the Key Vault resource."
}
