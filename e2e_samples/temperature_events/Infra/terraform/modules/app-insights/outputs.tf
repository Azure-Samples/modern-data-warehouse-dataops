output "instrumentation_key" {
  value       = azurerm_application_insights.app_insights.instrumentation_key
  description = "Instrumentation key for application insights"
  sensitive   = true
}
