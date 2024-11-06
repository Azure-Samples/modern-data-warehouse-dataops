variable "resource_group_name" {
  description = "Resource Group name to host keyvault"
  type        = string
}

variable "location" {
  description = "Loaction where the resources are to be deployed"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account names and containers"
  type        = string
  default     = "batchstore"
}

variable "storage_suffix" {
  description = "Suffix for batch storage account name"
  type        = string
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account. "
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Defines the Kind of account. "
  type        = string
  default     = "StorageV2"
}

variable "account_tier" {
  description = "Defines the Tier to use for this storage account."
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "virtual_network_subnet_id" {
  description = "virtual_network_subnet_id"
}

variable "default_action" {
  default = "Allow"
}
