variable "capacity_id" {
  description = "The Fabric capacity id"
  type        = string
}

variable "workspace_name" {
  description = "The display name of the Fabric workspace"
  type        = string
}

variable "workspace_description" {
  description = "The description of the Fabric workspace"
  type        = string
}

variable "workspace_identity_type" {
  description = "Indicates the workspace identity type"
  type        = string
  default     = "SystemAssigned"
}
