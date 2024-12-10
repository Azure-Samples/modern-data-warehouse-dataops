output "secret_name" {
  value = var.enable ? azurerm_key_vault_secret.secret[0].name : null
}

output "secret_value" {
  value     = var.enable ? azurerm_key_vault_secret.secret[0].value : null
  sensitive = true
}
