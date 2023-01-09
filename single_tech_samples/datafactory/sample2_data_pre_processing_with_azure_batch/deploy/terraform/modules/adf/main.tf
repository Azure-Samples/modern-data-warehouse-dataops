locals {
  adf_integration_runtime_azure_name = "IntegrationRuntime"
}

resource "random_string" "adf_suffix" {
  keepers = {
    "adf_name" = var.adf_name
  }
  length  = 8
  special = false
}

resource "azurerm_data_factory" "data_factory_avops" {
  name                            = "${var.adf_name}${random_string.adf_suffix.id}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  tags                            = var.tags
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "adf-private-endpoint" {
  name                = "${var.adf_name}-pvt-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.adf_name}-private-service-connection"
    private_connection_resource_id = azurerm_data_factory.data_factory_avops.id
    subresource_names              = ["dataFactory"]
    is_manual_connection           = false
  }
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "linked_service_storage" {
  name                     = ""
  data_factory_id          = azurerm_data_factory.data_factory_avops.id
  integration_runtime_name = azurerm_data_factory_integration_runtime_azure.managed_integeration_runtime.name
  url                      = var.storage_account_primary_dfs_url
  use_managed_identity     = true
}

resource "azurerm_data_factory_integration_runtime_azure" "managed_integeration_runtime" {
  name                    = local.adf_integration_runtime_azure_name
  data_factory_id         = azurerm_data_factory.data_factory_avops.id
  location                = var.location
  description             = "Managed Azure hosted intergartion runtime"
  compute_type            = "General"
  core_count              = 8
  time_to_live_min        = 10
  cleanup_enabled         = false
  virtual_network_enabled = true
}
