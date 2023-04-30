terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.22.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.11"
    }
  }
    required_version = ">= 1.3"
}

provider "azurerm" {
  # Configuration options
  features {}
}

locals {

  # 1st for loop takes storage accounts
  # 2nd for loop takes containers from the storage account selected in first for loop and prepares a map of
  # key -> storage account name - container name
  # value -> container name

  container_config = merge([
    for storage_account, containers in var.storage_account_container_config : {
      for containername, container_lifecycle_config in containers :
      join("", ["${storage_account}", "-${containername}"]) => containername
    }
  ]...)

  blob_type_blockblob      = "blockBlob"
  lifecycle_action_cool    = "cool"
  lifecycle_action_archive = "archive"
  lifecycle_action_delete  = "delete"
  azurecaf_name            = ""
}

# Resource group creation

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location
}

# Azurecaf to keep storage accounts name unique
resource "azurecaf_name" "sa_fn_datalifecycle" {
  name          = local.azurecaf_name
  resource_type = "azurerm_storage_account"
  suffixes      = [var.env]
  clean_input   = true
  random_length = 5
}

# Looping and creating multiple stoarge accounts based on the 
# keys and values of var.storage_account_map

resource "azurerm_storage_account" "storage_account" {
  for_each                 = var.storage_account_container_config
  name                     = join("",["${each.key}",azurecaf_name.sa_fn_datalifecycle.result])
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  is_hns_enabled           = var.is_hns_enabled
  nfsv3_enabled            = false
  
  blob_properties {
    last_access_time_enabled = var.last_access_time_enabled
  }
    depends_on = [
    azurerm_resource_group.resource_group
  ]
}

locals {
  storage_name_id_map = zipmap(values(azurerm_storage_account.storage_account)[*].name, values(azurerm_storage_account.storage_account)[*].id)
}

# Looping over the container_config and creating containers in 
# respective storage accounts.

resource "azurerm_storage_container" "storage-containers" {
  for_each            = local.container_config
  name                = each.value
  storage_account_name  = keys({for key, value in local.storage_name_id_map: key => value if startswith(key, split("-","${each.key}")[0])})[0]
  depends_on = [
    azurerm_storage_account.storage_account
  ]
}


resource "azurerm_storage_management_policy" "lifecycle" {
  for_each           = var.storage_account_container_config
  storage_account_id = values({for key, value in local.storage_name_id_map: key => value if startswith(key, "${each.key}")})[0]
  dynamic "rule" {
    for_each = { for key, value in "${each.value}" : key => value if can(value[local.lifecycle_action_cool]) }
    content {
      name    = join("",[rule.key,local.lifecycle_action_cool])
      enabled = true
      filters {
        prefix_match = [rule.key]
        blob_types   = [local.blob_type_blockblob]
      }
      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than = rule.value[local.lifecycle_action_cool]
        }
      }
    }
  }
  dynamic "rule" {
    for_each = { for key, value in "${each.value}" : key => value if can(value[local.lifecycle_action_archive]) }
    content {
      name    = join("",[rule.key,local.lifecycle_action_archive])
      enabled = true
      filters {
        prefix_match = [rule.key]
        blob_types   = [local.blob_type_blockblob]
      }
      actions {
        base_blob {
          tier_to_archive_after_days_since_modification_greater_than = rule.value[local.lifecycle_action_archive]
        }
      }
    }
  }
  dynamic "rule" {
    for_each = { for key, value in "${each.value}" : key => value if can(value[local.lifecycle_action_delete]) }
    content {
      name    = join("",[rule.key,local.lifecycle_action_delete])
      enabled = true
      filters {
        prefix_match = [rule.key]
        blob_types   = [local.blob_type_blockblob]
      }
      actions {
        base_blob {
          delete_after_days_since_modification_greater_than = rule.value[local.lifecycle_action_delete]
        }
      }
    }
  }
}
