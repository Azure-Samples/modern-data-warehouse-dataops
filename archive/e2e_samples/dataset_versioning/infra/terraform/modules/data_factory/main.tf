resource "azurerm_data_factory" "data_factory" {
  name                = "adf-${var.app_name}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      vsts_configuration,
    ]
  }
  tags = {
    "iac" = "terraform"
  }
}

resource "azurerm_data_factory_linked_service_key_vault" "df_kv_ls" {
  name                = var.kv_name
  resource_group_name = var.rg_name
  data_factory_name   = azurerm_data_factory.data_factory.name
  key_vault_id        = var.kv_id
}
