provider "azurerm" {
  features {}
}
provider "random" {}
provider "azuread" {}

resource "random_string" "base_name" {
  count   = var.base_name == "" ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

data "azuread_client_config" "current" {}

data "azuread_user" "current_user" {
  object_id = data.azuread_client_config.current.object_id
}

data "azurerm_role_definition" "storage_blob_contributor_role" {
  name = "Storage Blob Data Contributor"
}

locals {
  base_name         = var.base_name != "" ? lower(var.base_name) : random_string.base_name[0].result
  base_name_trimmed = replace(lower(local.base_name), "-", "")
  tags = {
    owner    = data.azuread_user.current_user.mail
    basename = local.base_name
  }
  notebook_defintion_path = "../../src/notebooks/nb-city-safety.ipynb"
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

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.tags
}

module "adls" {
  source               = "./modules/adls"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
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
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  keyvault_name       = "kv-${local.base_name}"
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = azuread_group.sg.id
  tags                = local.tags
}

module "loganalytics" {
  source              = "./modules/loganalytics"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  log_analytics_name  = "la-${local.base_name}"
  tags                = local.tags
}

module "application_insights" {
  source              = "./modules/appinsights"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "appi-${local.base_name}"
  workspace_id        = module.loganalytics.workspace_id
  application_type    = "other"
  tags                = local.tags
}

module "capacity" {
  source            = "./modules/fabric/capacity"
  capacity_name     = "cap${local.base_name_trimmed}"
  resource_group_id = azurerm_resource_group.rg.id
  location          = azurerm_resource_group.rg.location
  admin_email       = var.fabric_capacity_admin
  sku               = "F2"
  tags              = local.tags
}
