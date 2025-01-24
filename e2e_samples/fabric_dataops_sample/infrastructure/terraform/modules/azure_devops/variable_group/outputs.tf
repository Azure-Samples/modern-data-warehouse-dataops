output "variable_group_name" {
  description = "The name of the created Azure DevOps variable group"
  value       = azuredevops_variable_group.vargroup.name
}

output "variable_group_id" {
  description = "The ID of the created Azure DevOps variable group"
  value       = azuredevops_variable_group.vargroup.id
}
