output "instrumentation_key" {
  value = azurerm_application_insights.appinsights.instrumentation_key
}

output "app_id" {
  value = azurerm_application_insights.appinsights.app_id
}

output "connection_string" {
  value = azurerm_application_insights.appinsights.connection_string
}
