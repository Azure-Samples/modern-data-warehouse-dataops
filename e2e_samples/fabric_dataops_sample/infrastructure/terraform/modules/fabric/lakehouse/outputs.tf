output "lakehouse_id" {
  value       = fabric_lakehouse.lakehouse.id
  description = "Microsoft Fabric lakehouse id"
}

output "lakehouse_name" {
  value       = fabric_lakehouse.lakehouse.display_name
  description = "Microsoft Fabric lakehouse display name"
}
