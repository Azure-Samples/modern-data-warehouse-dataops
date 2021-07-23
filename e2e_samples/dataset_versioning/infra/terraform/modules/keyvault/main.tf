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

  access_policy {
    tenant_id          = var.client_config_current.tenant_id
    object_id          = var.client_config_current.object_id
    secret_permissions = local.client_config_secret_permissions
  }

  access_policy {
    tenant_id          = var.client_config_current.tenant_id
    object_id          = var.adf_identity_id
    secret_permissions = local.adf_identity_secret_permissions
  }
}
