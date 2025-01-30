variable "azure_devops_project_id" {
  description = "Azure DevOps project id"
  type        = string
}

variable "azure_devops_variable_group_name" {
  description = "Azure DevOps project name"
  type        = string
}

variable "azure_devops_variable_group_variables" {
  description = "Azure DevOps project variables"
  type        = list(string)
}

variable "azure_devops_keyvault_service_connection_id" {
  description = "Azure DevOps Azure RM service connection id"
  type        = string
}

variable "azure_devops_keyvault_name" {
  description = "Azure DevOps Key Vault name"
  type        = string
}
