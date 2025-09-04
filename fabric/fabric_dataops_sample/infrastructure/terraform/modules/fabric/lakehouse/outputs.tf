output "lakehouse_id" {
  value       = var.enable ? fabric_lakehouse.lakehouse[0].id : ""
  description = "Microsoft Fabric lakehouse id"
}

output "lakehouse_name" {
  value       = var.enable ? fabric_lakehouse.lakehouse[0].display_name : ""
  description = "Microsoft Fabric lakehouse display name"
}
