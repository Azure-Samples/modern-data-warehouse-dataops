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
  type        = map(string)
}