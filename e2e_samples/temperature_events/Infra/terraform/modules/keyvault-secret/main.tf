resource "azurerm_key_vault_secret" "kv_eventhub_conn_string" {
  name         = var.eventhub_name
  value        = var.eventhub_connection_string
  key_vault_id = var.keyvault_id
}
