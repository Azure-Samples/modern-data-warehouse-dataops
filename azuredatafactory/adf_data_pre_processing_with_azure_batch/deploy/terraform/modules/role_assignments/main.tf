locals {
  kv_access_policies = [
    { object_id = var.batch_uami_principal_id, key_permissions = [], secret_permissions = ["Get", "List"], certificate_permissions = [] },
    { object_id = var.adf_sami_principal_id, key_permissions = [], secret_permissions = ["Get", "List"], certificate_permissions = [] },
    { object_id = var.object_id, key_permissions = [], secret_permissions = ["Get", "List", "Delete", "Recover", "Backup", "Restore", "Set"], certificate_permissions = [] }
  ]
}

# In all storage accounts add Batch User Assigned MI as Blob Storage Data Contributor
resource "azurerm_role_assignment" "batch_adls_data_contributor_role" {
  scope                = var.adls_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.batch_uami_principal_id
}

# In all storage accounts add ADF MI as Blob Storage Data Contributor"
resource "azurerm_role_assignment" "adf_adls_data_contributor_role" {
  scope                = var.adls_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.adf_sami_principal_id
}

# In batch storage account add Batch System MI as Blob Storage Data Contributor
resource "azurerm_role_assignment" "batch_blob_data_contributor_role" {
  scope                = var.batch_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.batch_sami_principal_id
}

# In batch account IAM add ADF MI as controbutor
resource "azurerm_role_assignment" "adf_contributor_role" {
  scope                = var.batch_account_id
  role_definition_name = "Contributor"
  principal_id         = var.adf_sami_principal_id
}

# Give ADF access to batch storage account 
resource "azurerm_role_assignment" "adf_batch_blob_data_contributor_role" {
  scope                = var.batch_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.adf_sami_principal_id
}

resource "azurerm_role_assignment" "batch_blob_data_contributor_role_managed_identity" {
  scope                = var.batch_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.batch_uami_principal_id
}

# Role assignment for keyvault are handled by key vault access policy
resource "azurerm_key_vault_access_policy" "kv_access_policy_batch" {
  count                   = length(local.kv_access_policies)
  key_vault_id            = var.key_vault_id
  tenant_id               = var.tenant_id
  object_id               = local.kv_access_policies[count.index].object_id
  key_permissions         = local.kv_access_policies[count.index].key_permissions
  secret_permissions      = local.kv_access_policies[count.index].secret_permissions
  certificate_permissions = local.kv_access_policies[count.index].certificate_permissions
}

# Give Batch access to ACR
resource "azurerm_role_assignment" "batch_uami_acrpull_role" {
  principal_id                     = var.batch_uami_principal_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
