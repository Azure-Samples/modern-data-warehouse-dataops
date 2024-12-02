module "azure_databricks_workspace" {
  source      = "../../modules/adb-workspace"
  region      = var.region
  environment = var.environment
}

# module "metastore_and_users" {
#   source                        = "../../modules/metastore-and-users"
#   subscription_id               = var.subscription_id
#   databricks_workspace_name     = module.azure_databricks_workspace.databricks_workspace_name
#   region                        = var.region
#   resource_group                = module.azure_databricks_workspace.resource_group
#   aad_groups                    = var.aad_groups
#   account_id                    = var.account_id
#   metastore_name                = var.metastore_name
#   environment                   = var.environment
#   databricks_workspace_host_url = module.azure_databricks_workspace.databricks_workspace_host_url
#   databricks_workspace_id       = module.azure_databricks_workspace.databricks_workspace_id
#   prefix                        = replace(replace(replace(lower(module.azure_databricks_workspace.resource_group), "rg", ""), "-", ""), "_", "")
# }

# module "azure_databricks_unity_catalog" {
#   source                                 = "../../modules/adb-unity-catalog"
#   environment                            = var.environment
#   subscription_id                        = var.subscription_id
#   aad_groups                             = var.aad_groups
#   account_id                             = var.account_id
#   databricks_groups                      = module.metastore_and_users.databricks_groups
#   databricks_users                       = module.metastore_and_users.databricks_users
#   databricks_sps                         = module.metastore_and_users.databricks_sps
#   databricks_workspace_id                = module.azure_databricks_workspace.databricks_workspace_id
#   azurerm_databricks_access_connector_id = module.metastore_and_users.azurerm_databricks_access_connector_id
#   metastore_id                           = module.metastore_and_users.metastore_id
#   databricks_workspace_host_url          = module.azure_databricks_workspace.databricks_workspace_host_url
#   azurerm_storage_account_unity_catalog  = module.metastore_and_users.azurerm_storage_account_unity_catalog
# }
