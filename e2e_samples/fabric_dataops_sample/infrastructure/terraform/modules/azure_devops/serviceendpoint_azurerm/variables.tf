variable "azure_devops_project_id" {
  description = "Azure DevOps project id"
  type        = string
}

variable "azure_devops_serviceconnection_azurerm_name" {
  description = "Azure DevOps service connection (Azure RM) name"
  type        = string
}

variable "azure_devops_serviceconnection_sp_app_id" {
  description = "Azure DevOps service connection service principal app id"
  type        = string
}

variable "azure_devops_serviceconnection_sp_secret" {
  description = "Azure DevOps service connection service principal key"
  type        = string
  sensitive   = true
}

variable "azure_devops_serviceconnection_sp_tenant_id" {
  description = "Azure DevOps service connection service principal tenant id"
  type        = string
}

variable "azure_devops_serviceconnection_subscription_id" {
  description = "Azure DevOps service connection Azure subscription id"
  type        = string
}
