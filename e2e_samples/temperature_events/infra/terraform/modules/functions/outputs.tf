output "functions_tenant_id" {
  value       = azurerm_function_app.function_app.identity[0].tenant_id
  description = "Tenant id of Azure Functions later used for granting keyvault permission"
  sensitive   = true
}

output "functions_object_id" {
  value       = azurerm_function_app.function_app.identity[0].principal_id
  description = "Object id of Azure Functions later used for granting keyvault permission"
  sensitive   = true
}
