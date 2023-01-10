# ------------------------------------------------------------------------------------------------------
# Deploy VNET
# ------------------------------------------------------------------------------------------------------

module "virtual_network" {
  source              = "./modules/batchNetwork"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  address_prefix      = var.address_prefix
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
  kv_sku_name                = var.kv_sku_name
  virtual_network_subnet_ids = module.virtual_network.subnet_id
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
  account_tier              = var.account_tier
  account_replication_type  = var.account_replication_type
  account_kind              = var.account_kind
  is_hns_enabled            = var.is_hns_enabled
  nfsv3_enabled             = var.nfsv3_enabled
  default_action            = var.default_action
  is_manual_connection      = var.is_manual_connection
  virtual_network_subnet_id = module.virtual_network.subnet_id
  last_access_time_enabled  = var.last_access_time_enabled
  bypass                    = var.bypass
  blob_storage_cors_origins = var.blob_storage_cors_origins
}

# ------------------------------------------------------------------------------------------------------
# Deploy storage account for azure batch
# ------------------------------------------------------------------------------------------------------

module "storage_account" {
  source                    = "./modules/storage"
  storage_account_name      = var.storage_account_name
  resource_group_name       = var.resource_group_name
  tags                      = var.tags
  location                  = var.location
  account_tier              = var.batch_storage_account_tier
  account_replication_type  = var.batch_storage_account_replication_type
  account_kind              = var.batch_storage_account_kind
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
  name_suffix         = var.name_suffix
}

# ------------------------------------------------------------------------------------------------------
# Deploy container registry
# ------------------------------------------------------------------------------------------------------

module "container_registry" {
  source              = "./modules/containerRegistry"
  resource_group_name = var.resource_group_name
  location            = var.location
  acr_name            = var.acr_name
  batch_uami_id       = module.batch_managed_identity.managed_identity_id
  acr_sku             = var.acr_sku
  tags                = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy azure batch
# ------------------------------------------------------------------------------------------------------

module "azure_batch" {
  source                              = "./modules/azureBatch"
  batch_account_name                  = var.batch_account_name
  resource_group_name                 = var.resource_group_name
  location                            = var.location
  tags                                = var.tags
  batch_subnet_id                     = module.virtual_network.subnet_id
  storage_account_id                  = module.storage_account.storage_account_id
  storage_account_name                = module.storage_account.storage_account_name
  adls_account_name                   = module.adls.storage_account_name
  container_name                      = module.adls.storage_container_name
  pool_allocation_mode                = var.pool_allocation_mode
  storage_account_authentication_mode = var.storage_account_authentication_mode
  exec_pool_name                      = var.exec_pool_name
  orch_pool_name                      = var.orch_pool_name
  identity_type                       = var.identity_type
  storage_image_reference_exec_pool   = var.storage_image_reference_exec_pool
  storage_image_reference_orch_pool   = var.storage_image_reference_orch_pool
  vm_size_exec_pool                   = var.vm_size_exec_pool
  vm_size_orch_pool                   = var.vm_size_orch_pool
  node_agent_sku_id_exec_pool         = var.node_agent_sku_id_exec_pool
  node_agent_sku_id_orch_pool         = var.node_agent_sku_id_orch_pool
  batch_uami_id                       = module.batch_managed_identity.managed_identity_id
  batch_uami_principal_id             = module.batch_managed_identity.managed_identity_principal_id
  endpoint_configuration              = var.endpoint_configuration
  container_configuration_exec_pool   = var.container_configuration_exec_pool
  node_placement_exec_pool            = var.node_placement_exec_pool
  registry_server                     = module.container_registry.login_server
}

# ------------------------------------------------------------------------------------------------------
# Deploy azure data factory
# ------------------------------------------------------------------------------------------------------

module "data_factory" {
  source                          = "./modules/adf"
  adf_name                        = "${var.resource_group_name}-${var.adf_name}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  node_size                       = var.node_size
  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  virtual_network_id              = module.virtual_network.virtual_network_id
  subnet_id                       = module.virtual_network.subnet_id
  tags                            = var.tags
  storage_account_ids             = module.adls.storage_account_id
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
  batch_storage_account_id = module.storage_account.storage_account_id
  adf_sami_principal_id    = module.data_factory.adf_principal_id
  batch_sami_principal_id  = module.azure_batch.batch_sami_principal_id
  batch_uami_principal_id  = module.batch_managed_identity.managed_identity_principal_id
  batch_account_id         = module.azure_batch.batch_account_id
  key_vault_id             = module.key_vault.key_vault_id
  acr_id                   = module.container_registry.acr_id
  tenant_id                = module.key_vault.tenant_id
}
