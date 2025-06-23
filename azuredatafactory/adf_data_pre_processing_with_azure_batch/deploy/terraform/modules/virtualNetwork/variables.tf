variable "resource_group_name" {
  description = "Resource Group name to host keyvault"
  type        = string
}

variable "location" {
  description = "Loaction where the resources are to be deployed"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "virtualnet"
}

variable "vnet_suffix" {
  description = "Suffix for name of the virtual network"
  type        = string

}

variable "address_space" {
  description = "Address Space for the VNET"
  default     = "10.0.0.0/16"
}

variable "address_prefix" {
  description = "Address Prefix for the subnet"
  default     = "10.0.0.0/24"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "service_endpoints" {
  description = "Service Endpoints associated with the subnet"
}
