output "warehouse_id" {
  value       = fabric_lakehouse.warehouse.id
  description = "Microsoft Fabric warehouse id"
}

output "warehouse_name" {
  value       = fabric_lakehouse.warehouse.display_name
  description = "Microsoft Fabric warehouse display name"
}