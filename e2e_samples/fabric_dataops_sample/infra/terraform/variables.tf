variable "use_cli" {
  description = "Select whether for authentication you are using a user context or other kind of identity (true/false)"
  type        = bool
}

variable "use_msi" {
  description = "Indicate whether for authentication you are using a managed credential or service principal (true/false)"
  type        = bool
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
  type        = string
  description = "Tenant ID"
}

variable "subscription_id" {
<<<<<<< HEAD
  type        = string
  description = "Subscription ID"
=======
  type = string
  description = "Azure subscription ID"
>>>>>>> 0a9ca3d3a8dff013b8fb439d8f6e574b3ee1570a
}

variable "base_name" {
  description = "The base name of the deployed Azure resources"
  type        = string
}

variable "fabric_capacity_admin" {
  description = "The user principal name of Fabric capacity admin"
  type        = string
}

variable "fabric_workspace_admin_sg" {
  description = "The Entra security group of Fabric Workspace admins"
  type        = string
}

variable "rg_name" {
  description = "The resource group name where the Azure resources will be created"
  type        = string
}

variable "create_fabric_capacity" {
  description = "A flag to indicate whether a new Fabric capacity should/should not be created"
  type        = bool
}

variable "fabric_capacity_id" {
  description = "The ID of an existing Fabric capacity"
  type        = string
  default     = ""
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