variable "capacity_name" {
  type        = string
  description = "Name of the Fabric capacity."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group id"
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
}

variable "admin_members" {
  type        = list(string)
  description = "Fabric capacity admin members, can be email (for user) or id (for service principal)"
}

variable "sku" {
  type        = string
  description = "Fabric capacity SKU name"
  default     = "F2"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}