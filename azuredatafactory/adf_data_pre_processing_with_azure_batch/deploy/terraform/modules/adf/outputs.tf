output "adf_name" {
  value = azurerm_data_factory.data_factory.name
}

output "adf_resource_id" {
  value = azurerm_data_factory.data_factory.id
}

output "adf_principal_id" {
  value = azurerm_data_factory.data_factory.identity[0].principal_id
}
