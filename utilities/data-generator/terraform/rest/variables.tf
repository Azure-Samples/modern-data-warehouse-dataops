variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location for all resources."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random value so name is unique in your Azure subscription."
}

variable "resource_name" {
  type    = string
  default = "simulator"
}

variable "image" {
  type        = string
  description = "Container image to deploy."
  default     = "simulator-image"
}

variable "image_tag" {
  type        = string
  description = "version of image to deploy."
  default     = "latest"
}
