terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }

}

provider "random" {}
provider "azuread" {
  client_id     = var.client_id
  client_secret = var.client_secret
  tenant_id     = var.tenant_id
}
provider "fabric" {
  use_cli       = var.use_cli
  use_msi       = var.use_msi
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}
provider "azurerm" {
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription_id
  client_id                       = var.client_id
  client_secret                   = var.client_secret
  tenant_id                       = var.tenant_id
  features {}
}

resource "random_string" "base_name" {
  count   = var.base_name == "" ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

data "azuread_client_config" "current" {}

data "azurerm_role_definition" "storage_blob_contributor_role" {
  name = "Storage Blob Data Contributor"
}

data "azurerm_role_definition" "keyvault_secrets_officer" {
  name = "Key Vault Secrets Officer"
}

data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

data "azuread_group" "sg" {
  display_name     = var.fabric_workspace_admin_sg
  security_enabled = true
}

locals {
  base_name         = var.base_name != "" ? lower(var.base_name) : random_string.base_name[0].result
  base_name_trimmed = replace(lower(local.base_name), "-", "")
  tags = {
    owner    = data.azuread_client_config.current.client_id
    basename = local.base_name
  }
  notebook_001_defintion_path      = "../../src//notebooks/nb-city-safety.ipynb"
  notebook_002_defintion_path      = "../../src/notebooks/nb-covid-data.ipynb"
  data_pipeline_001_defintion_path = "../../src/data-pipelines/pl-covid-data-content.json"
}

module "adls" {
  source               = "./modules/adls"
  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = data.azurerm_resource_group.rg.location
  storage_account_name = "st${local.base_name_trimmed}"
  container_name       = "main"
  tags                 = local.tags
}

module "storage_blob_contributor_assignment" {
  source               = "./modules/role_assignment"
  principal_id         = data.azuread_group.sg.object_id
  role_definition_name = data.azurerm_role_definition.storage_blob_contributor_role.name
  scope                = module.adls.storage_account_id
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  keyvault_name       = "kv-${local.base_name}"
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = data.azuread_group.sg.object_id
  tags                = local.tags
  purge_protection    = false #toberemoved
}

module "keyvault_secrets_officer_role_assignment" {
  source               = "./modules/role_assignment"
  principal_id         = data.azuread_group.sg.object_id
  role_definition_name = data.azurerm_role_definition.keyvault_secrets_officer.name
  scope                = module.keyvault.keyvault_id
}

module "loganalytics" {
  source              = "./modules/loganalytics"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  log_analytics_name  = "la-${local.base_name}"
  tags                = local.tags
}

module "application_insights" {
  source              = "./modules/appinsights"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  name                = "appi-${local.base_name}"
  workspace_id        = module.loganalytics.workspace_id
  application_type    = "other"
  tags                = local.tags
}

# Pre-req: register the Microsoft.Fabric resource provider

module "fabric_capacity" {
  source                 = "./modules/fabric/capacity"
  create_fabric_capacity = var.create_fabric_capacity
  fabric_capacity_id     = var.fabric_capacity_id
  capacity_name          = "cap${local.base_name_trimmed}"
  resource_group_id      = data.azurerm_resource_group.rg.id
  location               = data.azurerm_resource_group.rg.location
  admin_members          = [data.azuread_client_config.current.object_id, var.fabric_capacity_admin]
  sku                    = "F2"
  tags                   = local.tags
}

module "fabric_workspace" {
  source = "./modules/fabric/workspace"

  capacity_id             = module.fabric_capacity.capacity_id
  workspace_name          = "ws-${local.base_name}"
  workspace_description   = "Fabric workspace for ${local.base_name} project"
  workspace_identity_type = "SystemAssigned"
}

module "fabric_workspace_role_assignment" {
  source         = "./modules/fabric/workspace_role_assignment"
  workspace_id   = module.fabric_workspace.workspace_id
  principal_id   = data.azuread_group.sg.object_id
  principal_type = "Group"
  role           = "Admin"
}

module "fabric_lakehouse" {
  source                = "./modules/fabric/lakehouse"
  workspace_id          = module.fabric_workspace.workspace_id
  lakehouse_name        = "lh_${local.base_name_trimmed}"
  lakehouse_description = "Main (default) Lakehouse"
}

module "fabric_environment" {
  source                  = "./modules/fabric/environment"
  environment_name        = "env-${local.base_name}"
  environment_description = "Default environment for ${local.base_name} project"
  workspace_id            = module.fabric_workspace.workspace_id
}

# shortcut creation will be done through python/bash script
# spark environment compute and libraries settings will also be done via scripts (not supported currently by TF provider)

module "fabric_spark_custom_pool" {
  source           = "./modules/fabric/spark_custom_pool"
  workspace_id     = module.fabric_workspace.workspace_id
  custom_pool_name = "sprk-${local.base_name}"
}

module "fabric_notebook_001" {
  source = "./modules/fabric/notebook"

  workspace_id             = module.fabric_workspace.workspace_id
  notebook_name            = "nb-city-safety"
  notebook_description     = "'nb-city-safety' with definition"
  notebook_definition_path = local.notebook_001_defintion_path
  tokens = {
    "ONELAKE_NAME"   = "onelake"
    "WORKSPACE_NAME" = module.fabric_workspace.workspace_name
    "LAKEHOUSE_NAME" = module.fabric_lakehouse.lakehouse_name
  }
  definition_update_enabled = true
}

module "fabric_notebook_002" {
  source = "./modules/fabric/notebook"

  workspace_id             = module.fabric_workspace.workspace_id
  notebook_name            = "nb-covid-data"
  notebook_description     = "'nb-covid-data' with definition"
  notebook_definition_path = local.notebook_002_defintion_path
  tokens = {
    "ONELAKE_NAME"   = "onelake"
    "WORKSPACE_NAME" = module.fabric_workspace.workspace_name
    "LAKEHOUSE_NAME" = module.fabric_lakehouse.lakehouse_name
  }
  definition_update_enabled = true
}

# below modules currently do not support Service Principal/Managed Identities execution context
# therefore they are enabled only when using user context (var_use_cli==true)

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

module "fabric_data_pipeline_001" {
  source = "./modules/fabric/data_pipeline"

  workspace_id                  = module.fabric_workspace.workspace_id
  data_pipeline_name            = "pl-covid-data"
  data_pipeline_description     = "'pl-covid-data' with definition"
  data_pipeline_definition_path = local.data_pipeline_001_defintion_path
  tokens = {
    "ONELAKE_NAME"   = "onelake"
    "WORKSPACE_NAME" = module.fabric_workspace.workspace_name
    "LAKEHOUSE_NAME" = module.fabric_lakehouse.lakehouse_name
    "NOTEBOOK_ID"    = module.fabric_notebook_001.notebook_id
    "WORKSPACE_ID"   = module.fabric_workspace.workspace_id
  }
  definition_update_enabled = true
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

  depends_on = [module.fabric_data_pipeline_001]
}

# EXCLUDED:
# deployment pipeline as is not supported by TF yet
# shortcut as it's not supported by TF yet
# trigger data pipeline not IaC