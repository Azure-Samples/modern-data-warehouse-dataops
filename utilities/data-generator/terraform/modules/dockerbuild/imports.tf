variable "resource_group" {
  type = string
}

variable "registry" {
  type = string
}

variable "image" {
  type = string
}

variable "image_tag" {
  type = string
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_container_registry" "acr" {
  name                = var.registry
  resource_group_name = data.azurerm_resource_group.rg.name
}
