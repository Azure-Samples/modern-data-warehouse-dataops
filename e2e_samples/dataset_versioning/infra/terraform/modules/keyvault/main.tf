resource "azurerm_key_vault" "keyvault" {
  name                        = "kv-${var.app_name}-${var.env}-${var.location}"
  location                    = var.location
  resource_group_name         = var.rg_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.client_config_current.tenant_id
  sku_name                    = "standard"
  soft_delete_enabled         = true
  purge_protection_enabled    = true

  tags = {
    "iac" = "terraform"
  }
}

resource "azurerm_key_vault_access_policy" "service_principal" {
  key_vault_id       = azurerm_key_vault.keyvault.id
  tenant_id          = var.client_config_current.tenant_id
  object_id          = var.client_config_current.object_id
  secret_permissions = local.get_set_delete_purge_list_permissions
}
