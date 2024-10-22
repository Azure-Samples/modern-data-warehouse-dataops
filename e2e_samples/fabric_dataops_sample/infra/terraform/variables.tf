variable "use_cli" {
  description = "Select whether for authentication you are using a user context or other kind of identity (true/false)"
  type = bool
}

variable "use_msi" {
  description = "Indicate whether for authentication you are using a managed credential or service principal (true/false)"
  type = bool
}

variable "client_id" {
  type = string
  description = "The Application ID of the SPN/MI used to run this deployment and that will be granted Capacity Admin access"
}

variable "client_secret" {
  type = string
  description = "The secret of the SPN used to run this deployment."
}

variable "tenant_id" {
  type = string
  description = "Tenant ID"
}

variable "subscription_id" {
  type = string
  description = "Azure subscription ID"
}

variable "base_name" {
  description = "The base name of the deployed Azure resources"
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
  default     = "westus3"
}

variable "fabric_capacity_admin" {
  description = "The Object ID of the group of Fabric capacity admins"
  type        = string
}

variable "fabric_workspace_admins" {
  description = "The Object ID of the group of Fabric Workspace admins"
  type        = string
}

variable "rg_name" {
  description = "The resource group name where the Azure resources will be created"
  type = string  
}

variable "create_fabric_capacity" {
  description = "A flag to indicate whether a new Fabric capacity should/should not be created"
  type = bool
}

variable "fabric_capacity_id" {
  description = "The ID of an existing Fabric capacity"
  type = string
  default = ""
}

variable "git_organization_name" {
  type        = string
  description = "The Git organization name"
}

variable "git_project_name" {
  type        = string
  description = "The Git project name"
}

variable "git_repository_name" {
  type        = string
  description = "The Git repository name"
}

variable "git_branch_name" {
  type        = string
  description = "The Git branch name"
}

variable "git_directory_name" {
  type        = string
  description = "The directory name for Fabric artifacts"
}