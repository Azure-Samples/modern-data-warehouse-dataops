data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "storage" {
  name                     = replace("st-${var.function_name}-${data.azurerm_resource_group.rg.tags.resource_name}", "-", "")
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_function_app" "function_app" {
  name                       = "func-${var.function_name}-${var.resource_name}"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  app_service_plan_id        = var.appservice_plan
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  os_type                    = "linux"

  version    = "~3"
  https_only = true

  identity {
    type = "SystemAssigned"
  }

  app_settings = var.appsettings
}
