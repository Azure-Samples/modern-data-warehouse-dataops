locals {
  base_name             = var.base_name != "" ? lower(var.base_name) : random_string.base_name[0].result
  base_name_trimmed     = replace(replace(local.base_name, "-", ""), "_", "")
  base_name_underscored = replace(local.base_name, "-", "_")
  tags = {
    basename    = local.base_name
    environment = var.environment_name
  }
  fabric_setup_notebook_name             = "nb-setup"
  fabric_standardize_notebook_name       = "nb-standardize"
  fabric_transform_notebook_name         = "nb-transform"
  fabric_main_pipeline_name              = "pl-main"
  setup_notebook_definition_path         = "../../src/notebooks/00_setup.ipynb"
  standardize_notebook_definition_path   = "../../src/notebooks/02_standardize.ipynb"
  transform_notebook_definition_path     = "../../src/notebooks/03_transform.ipynb"
  main_pipeline_definition_path          = "../../src/pipelines/00-main.json"
  storage_account_name                   = "st${local.base_name_trimmed}${var.environment_name}"
  keyvault_name                          = "kv-${local.base_name}-${var.environment_name}"
  log_analytics_name                     = "la-${local.base_name}-${var.environment_name}"
  appinsights_name                       = "appi-${local.base_name}-${var.environment_name}"
  fabric_capacity_name                   = var.create_fabric_capacity ? "cap${local.base_name_trimmed}${var.environment_name}" : var.fabric_capacity_name
  fabric_capacity_admins                 = split(",", var.fabric_capacity_admins)
  fabric_workspace_name                  = "ws-${local.base_name}-${var.environment_name}"
  fabric_lakehouse_name                  = "lh_${local.base_name_underscored}"
  fabric_environment_name                = "env-${local.base_name}"
  fabric_custom_pool_name                = "sprk-${local.base_name}"
  fabric_runtime_version                 = "1.3"
  git_variable_group_name                = "vg-${local.base_name}-${var.environment_name}"
  git_variable_group_w_keyvault_name     = "vg-kv-${local.base_name}-${var.environment_name}"
  git_service_connection_name            = "sc-${local.base_name}-${var.environment_name}"
  service_endpoint_authentication_scheme = var.use_msi ? "ManagedServiceIdentity" : "ServicePrincipal"
  fabric_adls_connection_name            = "conn-adls-${module.adls.storage_account_name}"
  storage_account_role_definition_id     = split("/", data.azurerm_role_definition.storage_blob_contributor_role.id)[4]
  git_integration_dependency             = var.deploy_fabric_items ? module.fabric_data_pipeline : module.fabric_workspace
}
