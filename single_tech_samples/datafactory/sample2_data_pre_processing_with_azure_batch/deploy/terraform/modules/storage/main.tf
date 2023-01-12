resource "random_string" "storage_suffix" {
  keepers = {
    "storage_account_name" = var.storage_account_name
  }
  length  = 8
  numeric = false
  upper   = false
  special = false
}

resource "azurerm_storage_account" "batch_storage" {
  name                     = "${var.storage_account_name}${var.tags.environment}${random_string.storage_suffix.id}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  tags                     = var.tags
  network_rules {
    default_action            = var.default_action
    virtual_network_subnet_ids = [var.virtual_network_subnet_id]
  }
}
