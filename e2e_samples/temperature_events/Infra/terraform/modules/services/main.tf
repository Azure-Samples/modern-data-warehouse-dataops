data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_name}"
  location = var.location

  tags = {
    environment   = var.environment
    resource_name = local.resource_name
  }
}

resource "azurerm_app_service_plan" "function_app" {
  name                = "plan-${local.resource_name}"
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

module "functions" {
  source              = "../functions"
  count               = length(var.functions_names)
  resource_group_name = azurerm_resource_group.rg.name
  function_name       = var.functions_names[count.index]
  appservice_plan     = azurerm_app_service_plan.function_app.id
  appsettings         = local.appsettings
}

module "eventhubs" {
  source = "../eventhubs"

  count               = length(var.event_hub_names)
  resource_group_name = azurerm_resource_group.rg.name
  eventhub_name       = var.event_hub_names[count.index]
  eventhub_config     = var.eventhub_config
}

module "keyvault" {
  source = "../keyvault"

  resource_group_name = azurerm_resource_group.rg.name
  kv_sku              = var.kv_sku
}

module "keyvault-policy" {
  count  = length(module.functions)
  source = "../keyvault-policy"

  keyvault_id = module.keyvault_id
  tenant_id   = element(module.functions, count.index)["functions_tenant_id"]
  object_id   = element(module.functions, count.index)["functions_object_id"]
}

module "keyvault-secret" {
  source = "../keyvault-secret"
  count  = length(var.event_hub_names)

  keyvault_id                = module.keyvault_id
  eventhub_name              = element(module.eventhubs, count.index)["eventhub_name"]
  eventhub_connection_string = element(module.eventhubs, count.index)["eventhub_connection_string"]
}
