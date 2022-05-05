data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_name}"
  location = var.location

  tags = {
    "environment" = var.environment
  }
}
resource "azurerm_key_vault" "kv" {
  name                = "kv-${local.resource_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = var.kv_sku
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault_access_policy" "azurerm_client_keyvault_policy" {
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = var.set_key_permissions
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
  name                = var.name
  location            = var.location
  function_name       = var.functions_names[count.index]
  appservice_plan     = azurerm_app_service_plan.function_app.id
  appsettings         = merge(local.appsettings, tomap({ "AzureWebJobs.${var.functions_names[0]}.Disabled" = count.index != 0, "AzureWebJobs.${var.functions_names[1]}.Disabled" = count.index != 1 }))
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

resource "azurerm_key_vault_access_policy" "keyvault_policy" {
  count              = length(module.functions)
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = element(module.functions, count.index)["functions_tenant_id"]
  object_id          = element(module.functions, count.index)["functions_object_id"]
  secret_permissions = var.key_permissions
}

resource "azurerm_key_vault_secret" "kv_eventhub_conn_string" {
  count        = length(var.event_hub_names)
  name         = "${element(var.event_hub_names, count.index)}-conn"
  value        = element(module.eventhubs, count.index)["eventhub_connection_string"]
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.keyvault_policy, azurerm_key_vault_access_policy.azurerm_client_keyvault_policy]
}

resource "azurerm_key_vault_secret" "kv_eventhub_name" {
  count        = length(var.event_hub_names)
  name         = "${element(var.event_hub_names, count.index)}-name"
  value        = element(module.eventhubs, count.index)["eventhub_name"]
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.keyvault_policy, azurerm_key_vault_access_policy.azurerm_client_keyvault_policy]
}

resource "azurerm_key_vault_secret" "kv_eventhub_name_space" {
  count        = length(var.event_hub_names)
  name         = "${element(var.event_hub_names, count.index)}-namespace"
  value        = element(module.eventhubs, count.index)["eventhub_namespace"]
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.keyvault_policy, azurerm_key_vault_access_policy.azurerm_client_keyvault_policy]
}

resource "azurerm_key_vault_secret" "kv_appinsights_conn_string" {
  name         = var.app_insights_name
  value        = azurerm_application_insights.app_insights.instrumentation_key
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.keyvault_policy, azurerm_application_insights.app_insights, azurerm_key_vault_access_policy.azurerm_client_keyvault_policy]
}

resource "azurerm_key_vault_secret" "kv_subscription_id" {
  name         = "subscription-id"
  value        = data.azurerm_client_config.current.subscription_id
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.azurerm_client_keyvault_policy]
}

resource "azurerm_key_vault_secret" "kv_rg" {
  name         = "rg-name"
  value        = azurerm_resource_group.rg.name
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.azurerm_client_keyvault_policy]
}
