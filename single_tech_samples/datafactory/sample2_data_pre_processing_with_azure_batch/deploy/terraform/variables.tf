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

variable "blob_storage_cors_origins" {
  description = "Blob storage cors origins"
  type        = set(string)
  default     = ["https://*.av.electric.com", "http://*.av.corp.electric.com", "https://*.av.corp.electric.com"]
}

variable "service_endpoints" {
  description = "Service Endpoints associated with the subnet"
  default     = ["Microsoft.KeyVault", "Microsoft.Storage"]
}
