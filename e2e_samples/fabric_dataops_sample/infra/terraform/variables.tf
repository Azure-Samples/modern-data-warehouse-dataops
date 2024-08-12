variable "base_name" {
  description = "The base name of the deployed Azure resources"
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
  default     = "austaliaeast"
}

variable "fabric_capacity_admin" {
  description = "The email of the Fabric capacity admin"
  type        = string
}