# data "azurerm_client_config" "current" {}

resource "random_string" "kv_suffix" {
  keepers = {
    "kv_name" = var.key_vault_name
  }
  length  = 8
  special = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = "${var.key_vault_name}${random_string.kv_suffix.id}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.kv_sku_name
  tags = var.tags

  network_acls {
    virtual_network_subnet_ids = [var.virtual_network_subnet_ids]
    default_action             = "Deny"
    bypass                     = "AzureServices"
  }
}

resource "azurerm_private_endpoint" "kv-private-endpoint" {
  name                = "${var.key_vault_name}-private-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  subnet_id           = var.virtual_network_subnet_ids

  private_service_connection {
    name                           = "${var.key_vault_name}-private-service-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}
