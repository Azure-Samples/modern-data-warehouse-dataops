module "datalifecycle" {
  source                           = "./modules/services/datalifecycle"
  blob_storage_cors_origins        = var.blob_storage_cors_origins
  storage_account_container_config = var.storage_account_container_config
  bypass                           = var.bypass
  resource_group_name              = var.resource_group_name
  location                         = var.location
  env                              = var.env
}