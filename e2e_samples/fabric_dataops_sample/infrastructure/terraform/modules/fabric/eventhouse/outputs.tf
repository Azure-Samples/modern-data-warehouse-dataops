output "eventhouse_id" {
  value       = fabric_eventhouse.eventhouse.id
  description = "Microsoft Fabric eventhouse id"
}

output "eventhouse_name" {
  value       = fabric_eventhouse.eventhouse.display_name
  description = "Microsoft Fabric eventhouse display name"
}
