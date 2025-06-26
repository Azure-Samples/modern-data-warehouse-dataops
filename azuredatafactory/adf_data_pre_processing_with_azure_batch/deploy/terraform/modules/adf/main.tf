locals {
  adf_integration_runtime_azure_name = "IntegrationRuntime"
}

resource "azurerm_data_factory" "data_factory" {
  name                            = "${var.adf_name}${var.tags.environment}${var.adf_suffix}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  tags                            = var.tags
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "linked_service_storage" {
  name                     = "AzureDataLakeStorage_LS"
  data_factory_id          = azurerm_data_factory.data_factory.id
  integration_runtime_name = azurerm_data_factory_integration_runtime_azure.managed_integeration_runtime.name
  url                      = var.storage_account_primary_dfs_url
  use_managed_identity     = true
}

resource "azurerm_data_factory_linked_service_key_vault" "linked_service_keyvault" {
  name                    = "AzureKeyVault_LS"
  data_factory_id = azurerm_data_factory.data_factory.id
  key_vault_id = var.key_vault_id
}

resource "azurerm_data_factory_integration_runtime_azure" "managed_integeration_runtime" {
  name                    = local.adf_integration_runtime_azure_name
  data_factory_id         = azurerm_data_factory.data_factory.id
  location                = var.location
  description             = "Managed Azure hosted intergartion runtime"
  compute_type            = "General"
  core_count              = 8
  time_to_live_min        = 10
  cleanup_enabled         = false
  virtual_network_enabled = true
}
