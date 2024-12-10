resource "random_string" "base_name" {
  count   = var.base_name == "" ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

module "adls" {
  source               = "./modules/adls"
  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = data.azurerm_resource_group.rg.location
  storage_account_name = local.storage_account_name
  container_name       = "main"
  tags                 = local.tags
}

module "storage_blob_contributor_assignment_001" {
  source               = "./modules/role_assignment"
  principal_id         = data.azuread_group.fabric_workspace_admin.object_id
  role_definition_name = data.azurerm_role_definition.storage_blob_contributor_role.name
  scope                = module.adls.storage_account_id
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  keyvault_name       = local.keyvault_name
  tenant_id           = var.tenant_id
  tags                = local.tags
}

module "keyvault_secrets_officer_assignment_001" {
  source               = "./modules/role_assignment"
  principal_id         = data.azuread_group.fabric_workspace_admin.object_id
  role_definition_name = data.azurerm_role_definition.keyvault_secrets_officer.name
  scope                = module.keyvault.keyvault_id
}

module "loganalytics" {
  source              = "./modules/loganalytics"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  log_analytics_name  = local.log_analytics_name
  tags                = local.tags
}

module "appinsights" {
  source              = "./modules/appinsights"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  name                = local.appinsights_name
  workspace_id        = module.loganalytics.workspace_id
  application_type    = "other"
  tags                = local.tags
}

module "fabric_capacity" {
  source                 = "./modules/fabric/capacity"
  create_fabric_capacity = var.create_fabric_capacity
  capacity_name          = local.fabric_capacity_name
  resource_group_id      = data.azurerm_resource_group.rg.id
  location               = data.azurerm_resource_group.rg.location
  admin_members          = local.fabric_capacity_admins
  sku                    = "F2"
  tags                   = local.tags
}

module "fabric_workspace" {
  source = "./modules/fabric/workspace"

  capacity_id             = module.fabric_capacity.capacity_id
  workspace_name          = local.fabric_workspace_name
  workspace_description   = "Fabric workspace for ${local.base_name} project"
  workspace_identity_type = "SystemAssigned"
}

module "storage_blob_contributor_assignment_002" {
  source               = "./modules/role_assignment"
  principal_id         = module.fabric_workspace.workspace_identity_service_principal_id
  role_definition_name = data.azurerm_role_definition.storage_blob_contributor_role.name
  scope                = module.adls.storage_account_id

  depends_on = [module.fabric_workspace]
}

module "fabric_workspace_role_assignment" {
  source         = "./modules/fabric/workspace_role_assignment"
  workspace_id   = module.fabric_workspace.workspace_id
  principal_id   = data.azuread_group.fabric_workspace_admin.object_id
  principal_type = "Group"
  role           = "Admin"
}

module "fabric_lakehouse" {
  source                = "./modules/fabric/lakehouse"
  workspace_id          = module.fabric_workspace.workspace_id
  lakehouse_name        = local.fabric_lakehouse_name
  lakehouse_description = "Main (default) Lakehouse"
}

module "fabric_environment" {
  source                  = "./modules/fabric/environment"
  environment_name        = local.fabric_environment_name
  environment_description = "Default environment for ${local.base_name} project"
  workspace_id            = module.fabric_workspace.workspace_id
}

# shortcut creation will be done through python/bash script
# spark environment compute and libraries settings will also be done via scripts (not supported currently by TF provider)
module "fabric_spark_custom_pool" {
  source           = "./modules/fabric/spark_custom_pool"
  workspace_id     = module.fabric_workspace.workspace_id
  custom_pool_name = local.fabric_custom_pool_name
}

module "fabric_setup_notebook" {
  source                   = "./modules/fabric/notebook"
  workspace_id             = module.fabric_workspace.workspace_id
  notebook_name            = local.fabric_setup_notebook_name
  notebook_definition_path = local.setup_notebook_definition_path
  tokens = {
    "lakehouse_name" = module.fabric_lakehouse.lakehouse_name
    "lakehouse_id"   = module.fabric_lakehouse.lakehouse_id
    "workspace_id"   = module.fabric_workspace.workspace_id
    "environment_id" = module.fabric_environment.environment_id
  }
}

module "fabric_standardize_notebook" {
  source                   = "./modules/fabric/notebook"
  workspace_id             = module.fabric_workspace.workspace_id
  notebook_name            = local.fabric_standardize_notebook_name
  notebook_definition_path = local.standardize_notebook_definition_path
  tokens = {
    "lakehouse_name" = module.fabric_lakehouse.lakehouse_name
    "lakehouse_id"   = module.fabric_lakehouse.lakehouse_id
    "workspace_id"   = module.fabric_workspace.workspace_id
    "environment_id" = module.fabric_environment.environment_id
  }
}

module "fabric_transform_notebook" {
  source                   = "./modules/fabric/notebook"
  workspace_id             = module.fabric_workspace.workspace_id
  notebook_name            = local.fabric_transform_notebook_name
  notebook_definition_path = local.transform_notebook_definition_path
  tokens = {
    "lakehouse_name" = module.fabric_lakehouse.lakehouse_name
    "lakehouse_id"   = module.fabric_lakehouse.lakehouse_id
    "workspace_id"   = module.fabric_workspace.workspace_id
    "environment_id" = module.fabric_environment.environment_id
  }
}

# The service principal/managed identity is not grated RBAC permissions to access secrets.
# Therefore, the secrets are stored in the AKV only when using user context (var_use_cli==true).
module "key_vault_secret_001" {
  enable       = var.use_cli
  source       = "./modules/keyvault_secret"
  name         = var.kv_appinsights_connection_string_name
  value        = module.appinsights.connection_string
  key_vault_id = module.keyvault.keyvault_id
  content_type = "Application Insights Connection String"
  tags         = local.tags
}

# Below modules currently do not support service principal/managed identity execution context.
# Therefore they are enabled only when using user context (var_use_cli==true).
module "fabric_data_pipeline" {
  enable                        = var.use_cli
  source                        = "./modules/fabric/data_pipeline"
  data_pipeline_name            = local.fabric_main_pipeline_name
  data_pipeline_definition_path = local.main_pipeline_definition_path
  workspace_id                  = module.fabric_workspace.workspace_id
  tokens = {
    "workspace_name"          = module.fabric_workspace.workspace_name
    "workspace_id"            = module.fabric_workspace.workspace_id
    "lakehouse_name"          = module.fabric_lakehouse.lakehouse_name
    "lakehouse_id"            = module.fabric_lakehouse.lakehouse_id
    "setup_notebook_id"       = module.fabric_setup_notebook.notebook_id
    "standardize_notebook_id" = module.fabric_standardize_notebook.notebook_id
    "transform_notebook_id"   = module.fabric_transform_notebook.notebook_id
  }
}

module "fabric_spark_environment_settings" {
  enable          = var.use_cli
  source          = "./modules/fabric/spark_environment_settings"
  workspace_id    = module.fabric_workspace.workspace_id
  environment_id  = module.fabric_environment.environment_id
  spark_pool_name = module.fabric_spark_custom_pool.spark_custom_pool_name
}

module "fabric_spark_workspace_settings" {
  enable            = var.use_cli
  source            = "./modules/fabric/spark_workspace_settings"
  environment_name  = module.fabric_environment.environment_name
  workspace_id      = module.fabric_workspace.workspace_id
  default_pool_name = module.fabric_spark_custom_pool.spark_custom_pool_name

  depends_on = [module.fabric_spark_environment_settings]
}

module "fabric_workspace_git_integration" {
  enable                  = var.use_cli
  source                  = "./modules/fabric/git_integration"
  workspace_id            = module.fabric_workspace.workspace_id
  initialization_strategy = "PreferWorkspace"
  project_name            = var.git_project_name
  organization_name       = var.git_organization_name
  branch_name             = var.git_branch_name
  directory_name          = var.git_directory_name
  repository_name         = var.git_repository_name
  git_provider_type       = "AzureDevOps"

  depends_on = [module.fabric_data_pipeline]
}
