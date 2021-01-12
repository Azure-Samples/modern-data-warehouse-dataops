resource "azurerm_key_vault_secret" "kv_eventhub_conn_string" {
  name         = var.instrumentation_key_name
  value        = var.instrumentation_key_value
  key_vault_id = var.keyvault_id
}
