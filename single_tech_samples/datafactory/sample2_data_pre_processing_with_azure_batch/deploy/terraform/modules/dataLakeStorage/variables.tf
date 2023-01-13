variable "resource_group_name" {
  description = "Resource Group name to host keyvault"
  type        = string
}

variable "location" {
  description = "Loaction where the resources are to be deployed"
  type        = string
}

variable "data_lake_store_name" {
  description = "Name of the storage account"
  type        = string
  default     = "datalakestore"
}

variable "adls_suffix" {
  description = "Suffix for name of the data lake storage account"
  type        = string
}

variable "container_name" {
  description = "Name of the storage container"
  type        = string
  default     = "data"
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account. "
  type        = string
  default     = "ZRS"
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

variable "is_hns_enabled" {
  description = "Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "nfsv3_enabled" {
  description = "Is NFSv3 protocol enabled?"
  type        = bool
  default     = true
}

variable "virtual_network_subnet_id" {
  description = "virtual network subnet ID"
}

variable "bypass" {
  description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices."
  type        = set(string)
  default     = ["AzureServices"]
}

variable "default_action" {
  description = "Specifies the default action of allow or deny when no other rules match. "
  type        = string
  default     = "Deny"
}

variable "is_manual_connection" {
  description = "Does the Private Endpoint require Manual Approval from the remote resource owner?"
  type        = bool
  default     = false
}
variable "last_access_time_enabled" {
  description = "Does last access time enabled?"
  type        = bool
  default     = true
}

variable "blob_storage_cors_origins" {
  description = "Blob storage CORS origins"
  type        = list(any)
}
