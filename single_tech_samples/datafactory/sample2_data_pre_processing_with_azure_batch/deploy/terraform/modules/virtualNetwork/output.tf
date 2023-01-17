output "virtual_network_name" {
  value = azurerm_virtual_network.virtual_network.name
}

output "subnet_name" {
  value = azurerm_subnet.subnet.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.virtual_network.id
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}
