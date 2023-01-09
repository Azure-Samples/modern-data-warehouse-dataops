output "batch_account_id" {
  value = azurerm_batch_account.batch_account.id
}

output "batch_account_name" {
  value = azurerm_batch_account.batch_account.name
}

output "batch_sami_principal_id" {
  value = azurerm_batch_account.batch_account.identity[0].principal_id
}