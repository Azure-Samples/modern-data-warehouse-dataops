# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  description = "Resource group name that the service uses"
}

variable "kv_sku" {
  type        = string
  description = "SKU of the keyvault to create"
}

variable "resource_name" {
  type        = string
  description = "Name of this service"
}

variable "location" {
  type        = string
  description = "Location where keyvault is provisioned to"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "key_permissions" {
  type        = list(string)
  description = "List of key permissions, must be one or more from the following: backup, create, decrypt, delete, encrypt, get, import, list, purge, recover, restore, sign, unwrapKey, update, verify and wrapKey"
  default     = ["set", "get", ]
}
