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

resource "azurerm_key_vault_access_policy" "principal_id" {
  key_vault_id       = var.kv_id
  tenant_id          = azurerm_data_factory.data_factory.identity.0.tenant_id
  object_id          = azurerm_data_factory.data_factory.identity.0.principal_id
  secret_permissions = ["Get"]
}
