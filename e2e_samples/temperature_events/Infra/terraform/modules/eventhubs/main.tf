data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_eventhub_namespace" "eventhub" {
  name                     = "evh-${var.eventhub_name}-${data.azurerm_resource_group.rg.tags.resource_name}"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  sku                      = var.eventhub_config.sku
  capacity                 = var.eventhub_config.capacity
  auto_inflate_enabled     = true
  maximum_throughput_units = var.eventhub_config.max_capacity
}

resource "azurerm_eventhub" "eventhub" {
  name                = "evhtopic-${var.eventhub_name}-${data.azurerm_resource_group.rg.tags.resource_name}"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  resource_group_name = data.azurerm_resource_group.rg.name
  partition_count     = var.eventhub_config.partition_count
  message_retention   = var.eventhub_config.message_retention
}

resource "azurerm_eventhub_consumer_group" "function_consumer_group" {
  name                = "functions"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.eventhub.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_eventhub_authorization_rule" "eventhub_authorization_rule" {
  name                = "authorization_rule"
  resource_group_name = data.azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.eventhub.name

  send   = true
  listen = true
}
