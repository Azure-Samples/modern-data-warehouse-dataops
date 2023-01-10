variable "resource_group_name" {
  description = "Resource Group name to host keyvault"
  type        = string
}

variable "location" {
  description = "Loaction where the resources are to be deployed"
  type        = string
}

variable "address_space" {
  description = "value"
  type        = string
}

variable "address_prefix" {
  description = "value"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "service_endpoints" {
  description = "Service Endpoints associated with the subnet"
}
