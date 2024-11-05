output "database_id" {
  value       = fabric_kql_database.kql_database.id
  description = "Microsoft Fabric kql database id"
}

output "database_name" {
  value       = fabric_kql_database.kql_database.display_name
  description = "Microsoft Fabric kql database display name"
}
