resource "azurerm_virtual_network" "virtual_network" {
  name                = "${var.vnet_name}${var.tags.environment}${var.vnet_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "${azurerm_virtual_network.virtual_network.name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [var.address_prefix]
  service_endpoints    = var.service_endpoints
}
