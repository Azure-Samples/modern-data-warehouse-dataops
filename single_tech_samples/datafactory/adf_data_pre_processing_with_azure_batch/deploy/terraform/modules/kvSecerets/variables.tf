variable "key_vault_id" {
  description = "Key vault name"
  type        = string
  default     = "keyvault"
}

variable "azure_batch_key_name" {
  description = "Name of Batch account key secret"
  type        = string
  default     = "azurebatchkey"
}

variable "batch_key_secret" {
  description = "Azure batch key"
  type        = string
}

variable "azure_batch_storage_key_name" {
  description = "Name of the Batch storage account key secret"
  type        = string
  default     = "azurebatchstoragekey"
}

variable "batch_storage_key_secret" {
  description = "Batch Storage account key"
  type        = string
}
