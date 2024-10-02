variable "base_name" {
  description = "The base name of the deployed Azure resources"
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
  default     = "westus3"
}

variable "fabric_capacity_admin" {
  description = "The Object ID of the group of Fabric capacity admins"
  type        = string
}


variable "fabric_workspace_admin" {
  description = "The Object ID of the group of Fabric capacity admins"
  type        = string
}

variable "rg_name" {
  description = "The resource group name where the Azure resources will be created"
  type = string  
}