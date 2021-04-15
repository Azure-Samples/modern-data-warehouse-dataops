output "adf_identity_id" {
  value       = azurerm_data_factory.data_factory.identity.0.principal_id
  description = "ID of ADF managed identity."
  sensitive   = true
}