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

variable "address_space" {
  description = "Address Space for the VNET"
}

variable "address_prefix" {
  description = "Address Prefix for the subnet"
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

variable "batch_storage_account_kind" {
  description = "Defines the Kind of account."
  type        = string
  default     = "StorageV2"
}

variable "batch_storage_account_tier" {
  description = "Defines the Tier to use for this storage account."
  type        = string
  default     = "Standard"
}

variable "batch_storage_account_replication_type" {
  description = "Defines the type of replication to use for this storage account. "
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Defines the Kind of account."
  type        = string
  default     = "StorageV2"
}

variable "account_tier" {
  description = "Defines the Tier to use for this storage account."
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account. "
  type        = string
  default     = "LRS"
}

variable "pool_allocation_mode" {
  description = "Specifies the mode to use for pool allocation."
  type        = string
  default     = "BatchService"
}

variable "storage_account_authentication_mode" {
  description = "Specifies the storage account authentication mode."
  type        = string
  default     = "BatchAccountManagedIdentity"
}

variable "identity_type" {
  description = "Specifies the type of Managed Service Identity that should be configured on this Batch Account."
  type        = string
  default     = "SystemAssigned"
}

variable "orch_pool_name" {
  description = "Specifies the name of the Batch pool."
  type        = string
}

variable "vm_size_orch_pool" {
  description = "Specifies the size of the VM created in the Batch pool."
  type        = string
  default     = "standard_a4_v2"
}

variable "node_agent_sku_id_orch_pool" {
  description = "Specifies the SKU of the node agents that will be created in the Batch pool."
  type        = string
  default     = "batch.node.ubuntu 20.04"
}

variable "storage_image_reference_orch_pool" {
  description = "A storage_image_reference for the virtual machines that will compose the Batch pool."
  type        = map(string)
}

variable "exec_pool_name" {
  description = "Specifies the name of the Batch pool."
  type        = string
}

variable "vm_size_exec_pool" {
  description = "Specifies the size of the VM created in the Batch pool."
  type        = string
  default     = "standard_d8_v3"
}

variable "node_agent_sku_id_exec_pool" {
  description = "Specifies the SKU of the node agents that will be created in the Batch pool."
  type        = string
  default     = "batch.node.ubuntu 20.04"
}

variable "storage_image_reference_exec_pool" {
  description = "A storage_image_reference for the virtual machines that will compose the Batch pool."
  type        = map(string)
}

variable "name_suffix" {
  description = "Suffix of Managed Identity name"
  type        = string
}

variable "endpoint_configuration" {
  type = map(string)
}

variable "container_configuration_exec_pool" {
  type        = string
  description = "The type of container configuration. "
}

variable "node_placement_exec_pool" {
  type        = string
  description = "The placement policy for allocating nodes in the pool."
}

variable "adf_name" {
  description = "Name of the Azure Data Factory"
  type        = string
}

variable "managed_virtual_network_enabled" {
  description = "Is Managed Virtual Network enabled?"
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "Key Vault resource name"
  type        = string
}

variable "node_size" {
  description = "The size of the nodes on which the Managed Integration Runtime runs."
  type        = string
}

variable "is_hns_enabled" {
  description = "Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2"
  type        = bool
  default     = true
}

variable "nfsv3_enabled" {
  description = "Is NFSv3 protocol enabled?"
  type        = bool
  default     = true
}

variable "bypass" {
  description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices."
  type        = set(string)
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
  description = "Blob storage cors origins"
  type        = set(string)
}

variable "kv_sku_name" {
  description = "keyvault sku - potential values Standard and Premium"
  type        = string
  default     = "standard"
}

variable "acr_sku" {
  description = "ACR sku type"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "service_endpoints" {
  description = "Service Endpoints associated with the subnet"
}
