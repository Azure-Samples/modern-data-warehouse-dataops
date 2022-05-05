data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

data "azurerm_client_config" "current" {}

module "keyvault" {
  source                = "../../modules/keyvault"
  app_name              = var.app_name
  env                   = var.env
  rg_name               = var.rg_name
  location              = var.location
  client_config_current = data.azurerm_client_config.current
  adf_identity_id       = module.azure_data_factory.adf_identity_id
}

module "azure_data_factory" {
  source   = "../../modules/data_factory"
  location = var.location
  rg_name  = var.rg_name
  app_name = var.app_name
  env      = var.env
  kv_id    = module.keyvault.kv_id
  kv_name  = module.keyvault.kv_name
}

module "data_lake" {
  source          = "../../modules/data_lake"
  location        = var.location
  rg_name         = var.rg_name
  app_name        = var.app_name
  env             = var.env
  kv_id           = module.keyvault.kv_id
  adf_identity_id = module.azure_data_factory.adf_identity_id
}


module "databricks" {
  source   = "../../modules/databricks"
  location = var.location
  rg_name  = var.rg_name
  app_name = var.app_name
  env      = var.env
}

module "sql_server" {
  source   = "../../modules/sql_server"
  location = var.location
  rg_name  = var.rg_name
  app_name = var.app_name
  kv_id    = module.keyvault.kv_id
  env      = var.env
}
