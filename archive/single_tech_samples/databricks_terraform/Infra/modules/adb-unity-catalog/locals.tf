locals {
  # data layers with names for storage containers and external locations
  data_layers = [
    {
      name              = "landing"
      storage_container = "landing"
      external_location = "landing"
    },
    {
      name              = "bronze"
      storage_container = "bronze"
      external_location = "bronze"
    },
    {
      name              = "silver"
      storage_container = "silver"
      external_location = "silver"
    },
    {
      name              = "gold"
      storage_container = "gold"
      external_location = "gold"
    },
    {
      name              = "checkpoints"
      storage_container = "checkpoints"
      external_location = "checkpoints"
    }
  ]

  # Catalog and environment configuration
  catalog_name   = "${var.environment}_catalog"
  environment    = var.environment
  merged_user_sp = merge(var.databricks_users, var.databricks_sps)
  aad_groups     = toset(var.aad_groups)
}
