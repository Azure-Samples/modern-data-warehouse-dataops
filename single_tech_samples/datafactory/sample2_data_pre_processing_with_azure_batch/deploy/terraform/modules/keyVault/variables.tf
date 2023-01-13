variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Loaction where the resources are to be deployed"
  type        = string
}

variable "kv_sku_name" {
  description = "keyvault sku - potential values Standard and Premium"
  type        = string
  default     = "standard"
}

variable "key_vault_name" {
  description = "Key vault name"
  type        = string
  default     = "keyvault"
}

variable "kv_suffix" {
  description = "Suffix for key vault name"
  type        = string
}

variable "virtual_network_subnet_id" {
  description = "Virtual network subnet ID"
}

variable "tags" {
  description = "Tags to associate with the key vault resource"
  type        = map(string)
}
