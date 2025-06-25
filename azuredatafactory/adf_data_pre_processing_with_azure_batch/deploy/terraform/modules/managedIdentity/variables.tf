variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
}

variable "location" {
  description = "Loaction where the resources are to be deployed"
  type        = string
}

variable "tags" {
  description = "Specifies the tags of the resource"
  default     = {}
}

variable "managed_identity_name" {
  description = "Name of the Managed Identity"
  type        = string
  default     = "batchmanagedidentity"
}

variable "managed_identity_suffix" {
  description = "Suffix of Managed Identity name"
  type        = string
}
