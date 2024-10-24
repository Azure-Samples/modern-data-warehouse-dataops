output "environment_id" {
  value       = fabric_environment.environment.id
  description = "Fabric environment id"
}

output "environment_name" {
  value       = fabric_environment.environment.display_name
  description = "Fabric environment display name"
}