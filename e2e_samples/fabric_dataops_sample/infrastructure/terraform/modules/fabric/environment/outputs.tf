output "environment_id" {
  value       = var.enable ? fabric_environment.environment[0].id : ""
  description = "Fabric environment id"
}

output "environment_name" {
  value       = var.enable ? fabric_environment.environment[0].display_name : ""
  description = "Fabric environment display name"
}
