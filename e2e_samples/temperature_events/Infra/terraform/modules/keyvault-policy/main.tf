resource "azurerm_key_vault_access_policy" "keyvault_set_policy" {
  key_vault_id       = var.keyvault_id
  tenant_id          = var.tenant_id
  object_id          = var.object_id
  secret_permissions = var.key_permissions
}
