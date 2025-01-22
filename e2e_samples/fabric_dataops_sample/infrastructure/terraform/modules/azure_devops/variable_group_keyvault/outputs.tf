output "variable_group_id" {
  description = "The ID of the created Azure DevOps variable group"
  value       = var.enable ? azuredevops_variable_group.vargroup[0].id : null
}
