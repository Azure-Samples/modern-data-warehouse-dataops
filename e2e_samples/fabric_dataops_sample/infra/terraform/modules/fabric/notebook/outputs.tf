output "notebook_id" {
  value       = fabric_notebook.notebook.id
  description = "Microsoft Fabric notebook id"
}

output "notebook_name" {
  value       = fabric_notebook.notebook.display_name
  description = "Microsoft Fabric notebook display name"
}