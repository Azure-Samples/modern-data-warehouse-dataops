output "adf_resource_id" {
  value = azurerm_data_factory.data_factory_avops.id
}

output "adf_principal_id" {
  value = azurerm_data_factory.data_factory_avops.identity[0].principal_id
}
