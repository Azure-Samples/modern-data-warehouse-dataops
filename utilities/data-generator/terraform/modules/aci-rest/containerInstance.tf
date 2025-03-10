resource "azurerm_container_group" "container" {
  name                = "simulator-rest"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  ip_address_type     = "Public"
  os_type             = "Linux"
  restart_policy      = "Never"
  image_registry_credential {
    username = data.azurerm_container_registry.acr.admin_username
    password = data.azurerm_container_registry.acr.admin_password
    server   = data.azurerm_container_registry.acr.login_server
  }

  container {
    name   = "sensor-simulator-rest"
    image  = "${var.registry}.azurecr.io/${var.image}:${var.image_tag}"
    cpu    = 0.5
    memory = 1

    ports {
      port     = 80
      protocol = "TCP"
    }
    environment_variables = {
      SENSORFILE       = "./collections/sensorLocations.json"
      DEFAULTDATACLASS = "kerbsidesensor"
      PORT             = "80"
    }
  }
}

output "container_ipv4_address" {
  value = azurerm_container_group.container.ip_address
}
