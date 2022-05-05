resource "random_password" "password" {
  length  = 16
  special = true
}

resource "random_id" "storage_account" {
  byte_length = 11
}

resource "azurerm_storage_account" "storage_account" {
  name                      = "st${var.app_name}sqldbaudit${var.env}"
  location                  = var.location
  resource_group_name       = var.rg_name
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
    hour_metrics {
      enabled               = true
      include_apis          = true
      version               = "1.0"
      retention_policy_days = 10
    }
    minute_metrics {
      enabled               = true
      include_apis          = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }

  tags = {
    "iac" = "terraform"
  }
}

resource "azurerm_sql_server" "sql_server" {
  name                         = "sql-${var.app_name}-${var.env}"
  location                     = var.location
  resource_group_name          = var.rg_name
  version                      = "12.0"
  administrator_login          = var.admin_user
  administrator_login_password = random_password.password.result
  extended_auditing_policy {
    storage_endpoint           = azurerm_storage_account.storage_account.primary_blob_endpoint
    storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
    retention_in_days          = 91
  }

  tags = {
    "iac" = "terraform"
  }
}

resource "azurerm_mssql_elasticpool" "mssql_elasticpool" {
  name                = "sqldb-${var.app_name}-${var.env}"
  resource_group_name = var.rg_name
  location            = var.location
  server_name         = azurerm_sql_server.sql_server.name
  license_type        = "LicenseIncluded"
  max_size_gb         = 5
  sku {
    name     = "GP_Gen5"
    tier     = "GeneralPurpose"
    family   = "Gen5"
    capacity = 4
  }
  per_database_settings {
    min_capacity = 0.25
    max_capacity = 4
  }

  tags = {
    "iac" = "terraform"
  }
}

resource "azurerm_mssql_database" "mssql_database" {
  server_id       = azurerm_sql_server.sql_server.id
  name            = "sqldb-${var.app_name}-${var.env}"
  elastic_pool_id = azurerm_mssql_elasticpool.mssql_elasticpool.id
  tags = {
    "iac" = "terraform"
  }
}

resource "azurerm_sql_firewall_rule" "sql_firewall_rule" {
  name                = var.app_name
  resource_group_name = var.rg_name
  server_name         = azurerm_sql_server.sql_server.name
  #checkov:skip=CKV_AZURE_11:Need to allow access from Azure Data Factory
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}


resource "azurerm_key_vault_secret" "key_vault_secret" {
  name         = "watermarkdb-connection"
  value        = "Server=tcp:${azurerm_sql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.mssql_database.name};Persist Security Info=False;User ID=${azurerm_sql_server.sql_server.administrator_login};Password=\"${azurerm_sql_server.sql_server.administrator_login_password}\";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = var.kv_id
}

resource "azurerm_key_vault_secret" "sql_db" {
  name         = "sql-db"
  value        = azurerm_mssql_database.mssql_database.name
  key_vault_id = var.kv_id
}

resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-password"
  value        = random_password.password.result
  key_vault_id = var.kv_id
}


resource "azurerm_key_vault_secret" "sql_table" {
  name         = "sql-table"
  value        = "source"
  key_vault_id = var.kv_id
}


resource "azurerm_key_vault_secret" "sql_userid" {
  name         = "sql-userid"
  value        = var.admin_user
  key_vault_id = var.kv_id
}


resource "azurerm_key_vault_secret" "sql_server" {
  name         = "sqlserver"
  value        = "${azurerm_sql_server.sql_server.name}.database.windows.net"
  key_vault_id = var.kv_id
}
