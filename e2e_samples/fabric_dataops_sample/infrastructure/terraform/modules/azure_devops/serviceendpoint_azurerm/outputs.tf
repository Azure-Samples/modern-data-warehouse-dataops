output "serviceendpoint_id" {
  description = "The ID of the created Azure DevOps service endpoint"
  value       = azuredevops_serviceendpoint_azurerm.serviceendpoint_azurerm.id
}

output "serviceendpoint_name" {
  description = "The name of the created Azure DevOps service endpoint"
  value       = azuredevops_serviceendpoint_azurerm.serviceendpoint_azurerm.service_endpoint_name
}
