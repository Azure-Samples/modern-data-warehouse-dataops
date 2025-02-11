variable "resource_group" {
  type = string
}

variable "resourcename" {
  type = string
}

variable "location" {
  type = string
}

# Create acr
resource "azurerm_container_registry" "acr" {
  name                = "${var.resourcename}acr"
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
}
