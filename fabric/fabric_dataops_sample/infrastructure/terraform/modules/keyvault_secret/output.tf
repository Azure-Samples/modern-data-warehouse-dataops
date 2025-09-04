output "secret_name" {
  value = azurerm_key_vault_secret.secret.name
}

output "secret_value" {
  value     = azurerm_key_vault_secret.secret.value
  sensitive = true
}
