output "managed_identity_name" {
  value = azurerm_user_assigned_identity.managed_identity.name
}

output "managed_identity_id" {
  value       = azurerm_user_assigned_identity.managed_identity.id
  description = "Specifies the resource id of the User Managed Identity"
}

output "managed_identity_principal_id" {
  value       = azurerm_user_assigned_identity.managed_identity.principal_id
  description = "Specifies the prinicipal id of the User Managed Identity"
}