output "service_endpoint_id" {
  description = "The ID of the created Azure DevOps service endpoint"
  value       = azuredevops_serviceendpoint_azurerm.azurerm.id
}

output "service_endpoint_name" {
  description = "The name of the created Azure DevOps service endpoint"
  value       = azuredevops_serviceendpoint_azurerm.azurerm.service_endpoint_name
}
