data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_name}"
  location = var.location

  tags = {
    "environment" = var.environment
  }
}

resource "azurerm_app_service_plan" "function_app" {
  name                = "plan-${local.resource_name}"
  location            = var.location
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
  resource_name       = local.resource_name
  location            = var.location
  function_name       = var.functions_names[count.index]
  appservice_plan     = azurerm_app_service_plan.function_app.id
  appsettings         = local.appsettings
  environment         = var.environment

}

module "eventhubs" {
  source = "../eventhubs"

  count               = length(var.event_hub_names)
  resource_group_name = azurerm_resource_group.rg.name
  resource_name       = local.resource_name
  location            = var.location
  eventhub_name       = var.event_hub_names[count.index]
  eventhub_config     = var.eventhub_config
}

module "keyvault" {
  source = "../keyvault"

  resource_group_name = azurerm_resource_group.rg.name
  resource_name       = local.resource_name
  location            = var.location
  kv_sku              = var.kv_sku
}

module "keyvault-policy" {
  count  = length(module.functions)
  source = "../keyvault-policy"

  keyvault_id = module.keyvault.keyvault_id
  tenant_id   = element(module.functions, count.index)["functions_tenant_id"]
  object_id   = element(module.functions, count.index)["functions_object_id"]
}

module "keyvault-secret" {
  source = "../keyvault-secret"
  count  = length(var.event_hub_names)

  keyvault_id                = module.keyvault.keyvault_id
  eventhub_name              = element(var.event_hub_names, count.index)
  eventhub_connection_string = element(module.eventhubs, count.index)["eventhub_connection_string"]

  depends_on = [module.keyvault-policy]
}
