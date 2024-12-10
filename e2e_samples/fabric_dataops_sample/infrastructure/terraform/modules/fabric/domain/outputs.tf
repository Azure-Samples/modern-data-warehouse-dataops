output "domain_id" {
  value       = fabric_domain.domain.id
  description = "Fabric domain id"
}

output "domain_name" {
  value       = fabric_domain.domain.display_name
  description = "Fabric domain display name"
}
