# ------------------------------------------------------------------------------------------------------
# Deploy VNET
# ------------------------------------------------------------------------------------------------------

module "virtual_network" {
  source              = "./modules/virtualNetwork"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  service_endpoints   = var.service_endpoints
}


# ------------------------------------------------------------------------------------------------------
# Deploy key vault
# ------------------------------------------------------------------------------------------------------

module "key_vault" {
  source                     = "./modules/keyVault"
  key_vault_name             = var.key_vault_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tags                       = var.tags
  virtual_network_subnet_id = module.virtual_network.subnet_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy data lake storage account
# ------------------------------------------------------------------------------------------------------

module "adls" {
  source                    = "./modules/dataLakeStorage"
  data_lake_store_name      = var.data_lake_store_name
  container_name            = var.container_name
  resource_group_name       = var.resource_group_name
  tags                      = var.tags
  location                  = var.location
  virtual_network_subnet_id = module.virtual_network.subnet_id
  blob_storage_cors_origins = var.blob_storage_cors_origins
}

# ------------------------------------------------------------------------------------------------------
# Deploy storage account for azure batch
# ------------------------------------------------------------------------------------------------------

module "batch_storage_account" {
  source                    = "./modules/storage"
  storage_account_name      = var.storage_account_name
  resource_group_name       = var.resource_group_name
  tags                      = var.tags
  location                  = var.location
  virtual_network_subnet_id = module.virtual_network.subnet_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy managed identity for batch account
# ------------------------------------------------------------------------------------------------------

module "batch_managed_identity" {
  source              = "./modules/managedIdentity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  name_suffix         = var.batch_account_name
}

# ------------------------------------------------------------------------------------------------------
# Deploy container registry
# ------------------------------------------------------------------------------------------------------

module "container_registry" {
  source              = "./modules/containerRegistry"
  resource_group_name = var.resource_group_name
  location            = var.location
  acr_name            = var.acr_name
  tags                = var.tags
  batch_uami_id       = module.batch_managed_identity.managed_identity_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy azure batch
# ------------------------------------------------------------------------------------------------------

module "azure_batch" {
  source                  = "./modules/azureBatch"
  batch_account_name      = var.batch_account_name
  resource_group_name     = var.resource_group_name
  location                = var.location
  tags                    = var.tags
  batch_subnet_id         = module.virtual_network.subnet_id
  storage_account_id      = module.batch_storage_account.storage_account_id
  storage_account_name    = module.batch_storage_account.storage_account_name
  adls_account_name       = module.adls.storage_account_name
  container_name          = module.adls.storage_container_name
  batch_uami_id           = module.batch_managed_identity.managed_identity_id
  batch_uami_principal_id = module.batch_managed_identity.managed_identity_principal_id
  registry_server         = module.container_registry.login_server
}

# ------------------------------------------------------------------------------------------------------
# Deploy azure data factory
# ------------------------------------------------------------------------------------------------------

module "data_factory" {
  source                          = "./modules/adf"
  adf_name                        = "${var.resource_group_name}-${var.adf_name}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  tags                            = var.tags
  virtual_network_id              = module.virtual_network.virtual_network_id
  subnet_id                       = module.virtual_network.subnet_id
  storage_account_primary_dfs_url = module.adls.storage_account_primary_dfs_url
  key_vault_id                    = module.key_vault.key_vault_id
  key_vault_name                  = module.key_vault.key_vault_name
  stoarge_linked_service          = module.adls.storage_account_name
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
  adls_id                  = module.adls.storage_account_id
  batch_storage_account_id = module.batch_storage_account.storage_account_id
  adf_sami_principal_id    = module.data_factory.adf_principal_id
  batch_sami_principal_id  = module.azure_batch.batch_sami_principal_id
  batch_uami_principal_id  = module.batch_managed_identity.managed_identity_principal_id
  batch_account_id         = module.azure_batch.batch_account_id
  key_vault_id             = module.key_vault.key_vault_id
  acr_id                   = module.container_registry.acr_id
  tenant_id                = module.key_vault.tenant_id
}
