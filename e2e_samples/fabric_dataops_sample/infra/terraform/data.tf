data "azurerm_role_definition" "storage_blob_contributor_role" {
  name = "Storage Blob Data Contributor"
}

data "azurerm_role_definition" "keyvault_secrets_officer" {
  name = "Key Vault Secrets Officer"
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azuread_group" "fabric_workspace_admin" {
  display_name     = var.fabric_workspace_admin_sg_name
  security_enabled = true
}