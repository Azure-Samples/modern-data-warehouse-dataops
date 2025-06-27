variable "create_fabric_capacity" {
  description = "A flag to indicate whether a new Fabric capacity should/should not be created"
  type        = bool
}

variable "capacity_name" {
  type        = string
  description = "Name of the Fabric capacity."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name where the Fabric capacity will be created"
}

variable "location" {
  description = "The Azure region where the Fabric capacity will be created"
  type        = string
}

variable "admin_members" {
  type        = set(string)
  description = "Fabric capacity admin members, can be email (for user) or id (for service principal)"
}

variable "sku" {
  type        = string
  description = "Fabric capacity SKU name"
  default     = "F2"

  validation {
    condition     = contains(["F2", "F4", "F8", "F16", "F32", "F64", "F128", "F256", "F512", "F1024", "F2048"], var.sku)
    error_message = "Please specify a valid Fabric Capacity SKU. Valid values are: [ 'F2', 'F4', 'F8', 'F16', 'F32', 'F64', 'F128', 'F256', 'F512', 'F1024', 'F2048' ]."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}
