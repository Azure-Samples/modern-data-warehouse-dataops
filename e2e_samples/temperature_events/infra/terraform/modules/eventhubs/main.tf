resource "azurerm_eventhub_namespace" "eventhub" {
  name                     = "evh-${var.eventhub_name}-${var.resource_name}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = var.eventhub_config.sku
  capacity                 = var.eventhub_config.capacity
  auto_inflate_enabled     = true
  maximum_throughput_units = var.eventhub_config.max_capacity
}

resource "azurerm_eventhub" "eventhub" {
  name                = "evhtopic-${var.eventhub_name}-${var.resource_name}"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  resource_group_name = var.resource_group_name
  partition_count     = var.eventhub_config.partition_count
  message_retention   = var.eventhub_config.message_retention
}

resource "azurerm_eventhub_consumer_group" "function_consumer_group" {
  name                = var.function_consumer_group
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.eventhub.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_authorization_rule" "eventhub_authorization_rule" {
  name                = var.authorization_rule
  resource_group_name = var.resource_group_name
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.eventhub.name

  send   = true
  listen = true
}
