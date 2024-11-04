output "workspace_id" {
  value       = fabric_workspace.workspace.id
  description = "Fabric workspace id"
}

output "workspace_name" {
  value       = fabric_workspace.workspace.display_name
  description = "Fabric workspace display name"
}

output "workspace_identity_service_principal_id" {
  value       = fabric_workspace.workspace.identity.service_principal_id
  description = "Fabric workspace resource group"
}
