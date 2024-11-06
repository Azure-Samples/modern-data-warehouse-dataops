variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Loaction where the resources are to be deployed"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "containerregistry"
}

variable "acr_suffix" {
  description = "Suffix for the ACR Name"
  type        = string
}

variable "batch_uami_id" {
  type        = string
  description = "Managed identity ID"
}

variable "acr_sku" {
  description = "value"
  type        = string
  default     = "Premium"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}
