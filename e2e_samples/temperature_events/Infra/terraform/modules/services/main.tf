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
  source = "../functions"

  count               = length(var.functions_names)
  resource_group_name = azurerm_resource_group.rg.name
  resource_name       = local.resource_name
  location            = var.location
  function_name       = var.functions_names[count.index]
  appservice_plan     = azurerm_app_service_plan.function_app.id
  appsettings         = local.appsettings
  environment         = var.environment
}

resource "azurerm_application_insights" "app_insights" {
  name                = "appi-${local.resource_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = var.appinsights_application_type
  retention_in_days   = var.retention
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

resource "azurerm_key_vault_access_policy" "keyvault_policy" {
  count              = length(module.functions)
  key_vault_id       = module.keyvault.keyvault_id
  tenant_id          = element(module.functions, count.index)["functions_tenant_id"]
  object_id          = element(module.functions, count.index)["functions_object_id"]
  secret_permissions = var.key_permissions
  depends_on         = [module.functions]
}

resource "azurerm_key_vault_secret" "kv_eventhub_conn_string" {
  count        = length(var.event_hub_names)
  name         = element(var.event_hub_names, count.index)
  value        = element(module.eventhubs, count.index)["eventhub_connection_string"]
  key_vault_id = module.keyvault.keyvault_id
  depends_on   = [azurerm_key_vault_access_policy.keyvault_policy]
}

resource "azurerm_key_vault_secret" "kv_appinsights_conn_string" {
  name         = var.app_insights_name
  value        = azurerm_application_insights.app_insights.instrumentation_key
  key_vault_id = module.keyvault.keyvault_id
  depends_on   = [azurerm_key_vault_access_policy.keyvault_policy, azurerm_application_insights.app_insights]
}
