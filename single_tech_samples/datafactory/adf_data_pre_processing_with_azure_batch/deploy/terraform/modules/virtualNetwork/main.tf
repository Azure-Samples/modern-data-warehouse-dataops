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

resource "azurerm_network_security_group" "batch-nsg" {
  name                = "${azurerm_virtual_network.virtual_network.name}-batch-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowTagCustom29876-29877Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "29876-29877"
    source_address_prefix      = "BatchNodeManagement.${var.location}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAnyCustom443Outbound"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "BatchNodeManagement.${var.location}"
  }

  security_rule {
    name                       = "AllowAnyCustom443OutboundStorage"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Storage.${var.location}"
  }
  
  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "subnet-nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.batch-nsg.id
}