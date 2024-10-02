terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.3"
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
provider "azuread" {}
provider "fabric" {
  use_cli = true
}
provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}

resource "random_string" "base_name" {
  count   = var.base_name == "" ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

data "azuread_client_config" "current" {}

# data "azuread_user" "current_user" {
#   object_id = data.azuread_client_config.current.object_id
# }

data "azurerm_role_definition" "storage_blob_contributor_role" {
  name = "Storage Blob Data Contributor"
}

locals {
  base_name         = var.base_name != "" ? lower(var.base_name) : random_string.base_name[0].result
  base_name_trimmed = replace(lower(local.base_name), "-", "")
  tags = {
    owner    = data.azuread_client_config.current.client_id
    basename = local.base_name
  }
  notebook_defintion_path = "../../notebooks/nb-city-safety.ipynb"
  data_pipeline_defintion_path = "../../data-pipelines/pl-covid-data-content.json"
}

resource "azuread_group" "sg" {
  display_name = "sg-${local.base_name}-admins"
  description  = "Admins for ${local.base_name} project"
  members = [
    data.azuread_client_config.current.object_id
  ]
  security_enabled = true
  prevent_duplicate_names = true
}

data "azurerm_resource_group" "rg" {
  name     = var.rg_name
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
  principal_id         = azuread_group.sg.id
  role_definition_name = data.azurerm_role_definition.storage_blob_contributor_role.name
  scope                = module.adls.storage_account_id
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  keyvault_name       = "kv-${local.base_name}"
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = azuread_group.sg.id
  tags                = local.tags
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
  source            = "./modules/fabric/capacity"
  capacity_name     = "cap${local.base_name_trimmed}"
  resource_group_id = data.azurerm_resource_group.rg.id
  location          = data.azurerm_resource_group.rg.location
  admin_members     = [data.azuread_client_config.current.object_id, var.fabric_workspace_admin]
  sku               = "F2"
  tags              = local.tags
}

module "fabric_workspace" {
  source = "./modules/fabric/workspace"

  capacity_id             = module.fabric_capacity.capacity_id
  workspace_name          = "ws-${local.base_name}"
  workspace_description   = "Fabric workspace for ${local.base_name} project"
  workspace_identity_type = "SystemAssigned"
}

module "fabric_workspace_role_assignment" {
  source = "./modules/fabric/workspace_role_assignment"
  workspace_id    = module.fabric_workspace.workspace_id
  principal_id    = azuread_group.sg.object_id
  principal_type  = "Group"
  role            = "Admin"  
}

module "fabric_workspace_role_assignment2" {
  source = "./modules/fabric/workspace_role_assignment"
  workspace_id    = module.fabric_workspace.workspace_id
  principal_id    = var.fabric_capacity_admin
  principal_type  = "Group"
  role            = "Admin"  
}

module "fabric_lakehouse" {
  source                = "./modules/fabric/lakehouse"
  workspace_id          = module.fabric_workspace.workspace_id
  lakehouse_name        = "lh_${local.base_name}"
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
  source                = "./modules/fabric/spark_custom_pool"
  workspace_id          = module.fabric_workspace.workspace_id
  custom_pool_name      = "sprk-${local.base_name}"
}

module "fabric_spark_environment_settings" {
  source                = "./modules/fabric/spark_environment_settings"
  workspace_id          = module.fabric_workspace.workspace_id
  environment_id        = module.fabric_environment.environment_id
  spark_pool_name       = module.fabric_spark_custom_pool.spark_custom_pool_name
}

module "fabric_spark_workspace_settings" {
  source                = "./modules/fabric/spark_workspace_settings"
  environment_name      = module.fabric_environment.environment_name
  workspace_id          = module.fabric_workspace.workspace_id
  default_pool_name     = module.fabric_spark_custom_pool.spark_custom_pool_name
}

module "fabric_notebook" {
  source                    = "./modules/fabric/notebook"
  workspace_id              = module.fabric_workspace.workspace_id
  notebook_name             = "nb-${local.base_name}"
  notebook_definition_path  = local.notebook_defintion_path
}

module "fabric_data_pipeline" {
  source                        = "./modules/fabric/data_pipeline"
  data_pipeline_name            = "pl-${local.base_name}"
  data_pipeline_definition_path = local.data_pipeline_defintion_path
  workspace_id                  = module.fabric_workspace.workspace_id
  tokens                        = {
    "workspace_name" = module.fabric_workspace.workspace_name
    "lakehouse_name" = module.fabric_lakehouse.lakehouse_name
  }
}

# domain/sub-domain?
# trigger pipeline
# connect to git
# deployment pipeline
