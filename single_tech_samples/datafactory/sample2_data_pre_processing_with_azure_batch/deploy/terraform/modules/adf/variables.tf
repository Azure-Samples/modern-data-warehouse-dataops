variable "adf_name" {
  description = "Name of the Azure Data Factory"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Loaction where the resources are to be deployed"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "managed_virtual_network_enabled" {
  description = "Is Managed Virtual Network enabled?"
  type        = bool
}

variable "subnet_id" {
  description = "Virtual network subnet ID"
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault resource name"
  type        = string
}

variable "storage_account_ids" {
  description = "storage account resource ids"
}

variable "storage_account_primary_dfs_url" {
  description = "Storage account primary dfs url"
}

variable "key_vault_id" {
  description = "Key Vault Linked Service ID"
  type        = string
}

variable "node_size" {
  description = "The size of the nodes on which the Managed Integration Runtime runs."
  type        = string
}

variable "stoarge_linked_service" {
  description = "Name of the storage account linked service"
  type        = string
}
