locals {
  base_name             = var.base_name != "" ? lower(var.base_name) : random_string.base_name[0].result
  base_name_trimmed     = replace(local.base_name, "-", "")
  base_name_underscored = replace(local.base_name, "-", "_")
  tags = {
    basename    = local.base_name
    environment = var.environment_name
  }
  fabric_setup_notebook_name           = "nb-setup"
  fabric_standardize_notebook_name     = "nb-standardize"
  fabric_transform_notebook_name       = "nb-transform"
  fabric_main_pipeline_name            = "pl-main"
  setup_notebook_definition_path       = "../../src/notebooks/00_setup.ipynb"
  standardize_notebook_definition_path = "../../src/notebooks/02_standardize.ipynb"
  transform_notebook_definition_path   = "../../src/notebooks/03_transform.ipynb"
  main_pipeline_definition_path        = "../../src/pipelines/00-main.json"
  storage_account_name                 = "st${local.base_name_trimmed}"
  keyvault_name                        = "kv-${local.base_name}"
  log_analytics_name                   = "la-${local.base_name}"
  appinsights_name                     = "appi-${local.base_name}"
  fabric_capacity_name                 = var.create_fabric_capacity ? "cap${local.base_name_trimmed}" : var.fabric_capacity_name
  fabric_capacity_admins               = split(",", var.fabric_capacity_admins)
  fabric_workspace_name                = "ws-${local.base_name}"
  fabric_lakehouse_name                = "lh_${local.base_name_underscored}"
  fabric_environment_name              = "env-${local.base_name}"
  fabric_custom_pool_name              = "sprk-${local.base_name}"
}
