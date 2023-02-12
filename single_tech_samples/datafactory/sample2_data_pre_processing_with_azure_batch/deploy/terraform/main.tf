# ------------------------------------------------------------------------------------------------------
# Generate a random suffix
# ------------------------------------------------------------------------------------------------------

resource "random_string" "common_suffix" {
  keepers = {
    "resource_group_name" = var.resource_group_name
  }
  length  = 8
  numeric = false
  upper   = false
  special = false
}

# ------------------------------------------------------------------------------------------------------
# Deploy VNET
# ------------------------------------------------------------------------------------------------------

module "virtual_network" {
  source              = "./modules/virtualNetwork"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  vnet_suffix         = random_string.common_suffix.id
  service_endpoints   = var.service_endpoints
}

# ------------------------------------------------------------------------------------------------------
# Deploy key vault
# ------------------------------------------------------------------------------------------------------

module "key_vault" {
  source                    = "./modules/keyVault"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  tags                      = var.tags
  kv_suffix                 = random_string.common_suffix.id
  virtual_network_subnet_id = module.virtual_network.subnet_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy data lake storage account
# ------------------------------------------------------------------------------------------------------

module "adls" {
  source                    = "./modules/dataLakeStorage"
  resource_group_name       = var.resource_group_name
  tags                      = var.tags
  location                  = var.location
  adls_suffix               = random_string.common_suffix.id
  virtual_network_subnet_id = module.virtual_network.subnet_id
  blob_storage_cors_origins = var.blob_storage_cors_origins
}

# ------------------------------------------------------------------------------------------------------
# Deploy storage account for azure batch
# ------------------------------------------------------------------------------------------------------

module "batch_storage_account" {
  source                    = "./modules/storage"
  resource_group_name       = var.resource_group_name
  tags                      = var.tags
  location                  = var.location
  storage_suffix            = random_string.common_suffix.id
  virtual_network_subnet_id = module.virtual_network.subnet_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy managed identity for batch account
# ------------------------------------------------------------------------------------------------------

module "batch_managed_identity" {
  source                  = "./modules/managedIdentity"
  resource_group_name     = var.resource_group_name
  location                = var.location
  managed_identity_suffix = random_string.common_suffix.id
  tags                    = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy container registry
# ------------------------------------------------------------------------------------------------------

module "container_registry" {
  source              = "./modules/containerRegistry"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  acr_suffix          = random_string.common_suffix.id
  batch_uami_id       = module.batch_managed_identity.managed_identity_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy azure batch
# ------------------------------------------------------------------------------------------------------

module "azure_batch" {
  depends_on = [
    module.container_registry
  ]
  source                  = "./modules/azureBatch"
  resource_group_name     = var.resource_group_name
  location                = var.location
  tags                    = var.tags
  batch_account_suffix    = random_string.common_suffix.id
  batch_subnet_id         = module.virtual_network.subnet_id
  storage_account_id      = module.batch_storage_account.storage_account_id
  storage_account_name    = module.batch_storage_account.storage_account_name
  adls_account_name       = module.adls.adls_account_name
  container_name          = module.adls.adls_container_name
  batch_uami_id           = module.batch_managed_identity.managed_identity_id
  batch_uami_principal_id = module.batch_managed_identity.managed_identity_principal_id
  registry_server         = module.container_registry.login_server
}

# ------------------------------------------------------------------------------------------------------
# Deploy azure data factory
# ------------------------------------------------------------------------------------------------------

module "data_factory" {
  source                          = "./modules/adf"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  tags                            = var.tags
  adf_suffix                      = random_string.common_suffix.id
  virtual_network_id              = module.virtual_network.virtual_network_id
  subnet_id                       = module.virtual_network.subnet_id
  storage_account_primary_dfs_url = module.adls.adls_account_primary_dfs_url
  key_vault_id                    = module.key_vault.key_vault_id
  key_vault_name                  = module.key_vault.key_vault_name
  stoarge_linked_service          = module.adls.adls_account_name
}

# ------------------------------------------------------------------------------------------------------
# Deploy Role assignments
# ------------------------------------------------------------------------------------------------------

module "role_assignments" {
  depends_on = [
    module.azure_batch,
    module.data_factory
  ]
  source                   = "./modules/role_assignments"
  adls_id                  = module.adls.adls_account_id
  batch_storage_account_id = module.batch_storage_account.storage_account_id
  adf_sami_principal_id    = module.data_factory.adf_principal_id
  batch_sami_principal_id  = module.azure_batch.batch_sami_principal_id
  batch_uami_principal_id  = module.batch_managed_identity.managed_identity_principal_id
  batch_account_id         = module.azure_batch.batch_account_id
  key_vault_id             = module.key_vault.key_vault_id
  acr_id                   = module.container_registry.acr_id
  tenant_id                = module.key_vault.tenant_id
  object_id                = module.key_vault.object_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy key vault secrets
# ------------------------------------------------------------------------------------------------------

module "kv_secrets" {
  depends_on = [
    module.role_assignments
  ]
  source                   = "./modules/kvSecerets"
  key_vault_id             = module.key_vault.key_vault_id
  batch_key_secret         = module.azure_batch.batch_account_primary_access_key
  batch_storage_key_secret = module.batch_storage_account.storage_account_primary_connection_string
}
