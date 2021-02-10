
output "eventhub_name" {
  value       = azurerm_eventhub.eventhub.name
  description = "Name of eventhub"
}

output "eventhub_connection_string" {
  value       = azurerm_eventhub_authorization_rule.eventhub_authorization_rule.primary_connection_string
  description = "Connection string for eventhub stored in keyvault"
  sensitive   = true
}

output "eventhub_namespace" {
  value       = azurerm_eventhub_namespace.eventhub.name
  description = "Name of eventhub namespace"
}
