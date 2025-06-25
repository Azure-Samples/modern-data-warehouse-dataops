output "batch_account_id" {
  value = azurerm_batch_account.batch_account.id
}

output "batch_account_name" {
  value = azurerm_batch_account.batch_account.name
}

output "batch_account_primary_access_key" {
  value = azurerm_batch_account.batch_account.primary_access_key
}

output "batch_sami_principal_id" {
  value = azurerm_batch_account.batch_account.identity[0].principal_id
}

output "exec_pool_name" {
  value = azurerm_batch_pool.exec_pool.name
}

output "orch_pool_name" {
  value = azurerm_batch_pool.orch_pool.name
}

output "batch_account_url" {
  value = azurerm_batch_account.batch_account.account_endpoint
}