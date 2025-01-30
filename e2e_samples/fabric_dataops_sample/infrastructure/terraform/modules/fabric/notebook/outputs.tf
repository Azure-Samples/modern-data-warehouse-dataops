output "notebook_id" {
  value       = var.enable ? fabric_notebook.notebook[0].id : ""
  description = "Microsoft Fabric notebook id"
}

output "notebook_name" {
  value       = var.enable ? fabric_notebook.notebook[0].display_name : ""
  description = "Microsoft Fabric notebook display name"
}
