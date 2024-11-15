variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
}

variable "keyvault_name" {
  description = "The name of the Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "The Tenant ID"
  type        = string
}

variable "object_id" {
  description = "The Object ID to assign permissions to"
  type        = string
}

variable "purge_protection" {
  description = "Whether to enable or not KeyVault purge protection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}