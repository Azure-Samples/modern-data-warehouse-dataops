resource "azurerm_storage_account" "storage_account" {
  name                      = "dls${var.app_name}${var.env}"
  resource_group_name       = var.rg_name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  is_hns_enabled            = "true"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  tags = {
    "iac" = "terraform"
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "data_lake_filesystem" {
  name               = "datalake"
  storage_account_id = azurerm_storage_account.storage_account.id

  ace {
    id          = var.adf_identity_id
    permissions = "rwx"
    scope       = "access"
    type        = "user"
  }
}

resource "azurerm_key_vault_secret" "datalake_secret" {
  name         = "datalake-connection"
  value        = azurerm_storage_account.storage_account.primary_connection_string
  key_vault_id = var.kv_id
}

resource "azurerm_key_vault_secret" "datalake_access_key" {
  name         = "datalake-access-key"
  value        = azurerm_storage_account.storage_account.primary_access_key
  key_vault_id = var.kv_id
}
