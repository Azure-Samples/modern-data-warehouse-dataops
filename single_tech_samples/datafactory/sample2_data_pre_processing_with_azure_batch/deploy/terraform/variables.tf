variable "resource_group_name" {
  description = "Resource Group name to host keyvault"
  type        = string
}

variable "location" {
  description = "key vault location"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "batch_account_name" {
  description = "Name of the Azure Batch Account"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "data_lake_store_name" {
  description = "Name of the storage account"
  type        = string
}

variable "container_name" {
  description = "Name of the storage container"
  type        = string
}

variable "adf_name" {
  description = "Name of the Azure Data Factory"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault resource name"
  type        = string
}

variable "blob_storage_cors_origins" {
  description = "Blob storage cors origins"
  type        = set(string)
  default     = ["https://*.av.electric.com", "http://*.av.corp.electric.com", "https://*.av.corp.electric.com"]
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "service_endpoints" {
  description = "Service Endpoints associated with the subnet"
  default     = ["Microsoft.KeyVault", "Microsoft.Storage"]
}
