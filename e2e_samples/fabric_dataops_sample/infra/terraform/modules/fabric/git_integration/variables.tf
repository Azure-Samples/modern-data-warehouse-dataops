variable "workspace_id" {
  type        = string
  description = "value of workspace id"
}

variable "initialization_strategy" {
  type        = string
  description = "value of initialization strategy"
}

variable "git_provider_type" {
  type        = string
  description = "The Git provider type (GitHub, AzureDevOps)"
  default     = "AzureDevOps"

}

variable "organization_name" {
  type        = string
  description = "The Git organization name"
}

variable "project_name" {
  type        = string
  description = "The Git project name"
}

variable "repository_name" {
  type        = string
  description = "The Git repository name"
}

variable "branch_name" {
  type        = string
  description = "The Git branch name"
}

variable "directory_name" {
  type        = string
  description = "The directory name for Fabric artifacts"
}