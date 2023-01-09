variable "resource_group_name" {
  description = "Resource Group name to host keyvault"
  type        = string
}

variable "location" {
  description = "key vault location"
  type        = string
}

variable "keyvault_sku_name" {
  description = "keyvault sku - potential values Standard and Premium"
  type        = string
  default     = "standard"
}

variable "kv_sku_name" {
  description = "keyvault sku - potential values Standard and Premium"
  type        = string
  default     = "standard"
}

variable "key_vault_name" {
  description = "Key vault name"
  type        = string
}

variable "virtual_network_subnet_ids" {
  description = "Virtual network subnet ID"
}

variable "tags" {
  description = "Tags to associate with the key vault resource"
  type        = map(string)
}
