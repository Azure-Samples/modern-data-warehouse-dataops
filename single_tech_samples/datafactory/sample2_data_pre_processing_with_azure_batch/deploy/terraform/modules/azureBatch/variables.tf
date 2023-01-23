variable "resource_group_name" {
  description = "Resource Group name to host keyvault"
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

variable "batch_account_name" {
  description = "Name of the Azure Batch Account"
  type        = string
  default     = "batchaccount"
}

variable "batch_account_suffix" {
  description = "Suffix for batch account name"
  type        = string
}

variable "adls_account_name" {
  description = "Name of the storage accpunt"
  type        = string
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

variable "batch_subnet_id" {
  description = "Virtual Network Subnet ID"
}

variable "storage_account_id" {
  description = "Specifies the storage account to use for the Batch account."
  type        = string
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
  default     = "orchestratorpool"
}

variable "vm_size_orch_pool" {
  description = "Specifies the size of the VM created in the Batch pool."
  type        = string
  default     = "standard_d2s_v3"
}

variable "node_agent_sku_id_orch_pool" {
  description = "Specifies the SKU of the node agents that will be created in the Batch pool."
  type        = string
  default     = "batch.node.ubuntu 20.04"
}

variable "storage_image_reference_orch_pool" {
  description = "A storage_image_reference for the virtual machines that will compose the Batch pool."
  type        = map(string)
  default = {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

variable "exec_pool_name" {
  description = "Specifies the name of the Batch pool."
  type        = string
  default     = "executionpool"
}

variable "vm_size_exec_pool" {
  description = "Specifies the size of the VM created in the Batch pool."
  type        = string
  default     = "standard_d2s_v3"
}

variable "node_agent_sku_id_exec_pool" {
  description = "Specifies the SKU of the node agents that will be created in the Batch pool."
  type        = string
  default     = "batch.node.ubuntu 20.04"
}

variable "storage_image_reference_exec_pool" {
  description = "A storage_image_reference for the virtual machines that will compose the Batch pool."
  type        = map(string)
  default = {
    publisher = "microsoft-azure-batch"
    offer     = "ubuntu-server-container"
    sku       = "20-04-lts"
    version   = "latest"
  }
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "container_name" {
  description = "Name of the stoarage container"
  type        = string
}

variable "batch_uami_id" {
  type        = string
  description = "Managed identity ID"
}

variable "batch_uami_principal_id" {
  type        = string
  description = "Managed identity prinicipal ID"
}

variable "endpoint_configuration" {
  type = map(string)
  default = {
    backend_port          = 22
    frontend_port_range   = "1-49999"
    protocol              = "TCP"
    access                = "Deny"
    priority              = "150"
    source_address_prefix = "*"
  }
}

variable "ip_sku" {
  type        = string
  description = "SKU for the public IP"
  default     = "Standard"
}

variable "container_configuration_exec_pool" {
  type        = string
  description = "The type of container configuration."
  default     = "DockerCompatible"
}

variable "node_placement_exec_pool" {
  type        = string
  description = "The placement policy for allocating nodes in the pool."
  default     = "Regional"
}

variable "registry_server" {
  description = "The URL that can be used to log into the container registry."
  type        = string
}
