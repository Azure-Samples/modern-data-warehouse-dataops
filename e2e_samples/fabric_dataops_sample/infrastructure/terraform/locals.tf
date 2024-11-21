locals {
  base_name             = var.base_name != "" ? lower(var.base_name) : random_string.base_name[0].result
  base_name_trimmed     = replace(local.base_name, "-", "")
  base_name_underscored = replace(local.base_name, "-", "_")
  tags = {
    basename    = local.base_name
    environment = var.environment_name
  }
  notebook_defintion_path      = "../../src/notebooks/nb-covid-data.ipynb"
  data_pipeline_defintion_path = "../../src/data-pipelines/pl-covid-data-content.json"
  storage_account_name         = "st${local.base_name_trimmed}"
  keyvault_name                = "kv-${local.base_name}"
  log_analytics_name           = "la-${local.base_name}"
  application_insights_name    = "appi-${local.base_name}"
  fabric_capacity_name         = var.create_fabric_capacity ? "cap${local.base_name_trimmed}" : var.fabric_capacity_name
  fabric_capacity_admins       = split(",", var.fabric_capacity_admins)
  fabric_workspace_name        = "ws-${local.base_name}"
  fabric_lakehouse_name        = "lh_${local.base_name_underscored}"
  fabric_environment_name      = "env-${local.base_name}"
  fabric_custom_pool_name      = "sprk-${local.base_name}"
  fabric_notebook_name         = "nb-${local.base_name}"
  fabric_data_pipeline_name    = "pl-${local.base_name}"
}
