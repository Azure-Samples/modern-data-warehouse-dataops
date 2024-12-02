# Storage credentials for external locations
resource "databricks_storage_credential" "external_mi" {
  name = "${local.environment}-location-mi-credential"

  azure_managed_identity {
    access_connector_id = var.azurerm_databricks_access_connector_id
  }

  owner   = "account_unity_admin"
  comment = "Storage credential for all external locations"
}

# Create storage containers explicitly for each data layer
resource "azurerm_storage_container" "landing" {
  name                 = local.data_layers[0].storage_container
  storage_account_name = var.azurerm_storage_account_unity_catalog.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "bronze" {
  name                 = local.data_layers[1].storage_container
  storage_account_name = var.azurerm_storage_account_unity_catalog.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
  name                 = local.data_layers[2].storage_container
  storage_account_name = var.azurerm_storage_account_unity_catalog.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                 = local.data_layers[3].storage_container
  storage_account_name = var.azurerm_storage_account_unity_catalog.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "checkpoint" {
  name                 = local.data_layers[4].storage_container
  storage_account_name = var.azurerm_storage_account_unity_catalog.name
  container_access_type = "private"
}

# Create external locations linked to the storage containers
resource "databricks_external_location" "landing" {
  name            = local.data_layers[0].external_location
  url             = format("abfss://%s@%s.dfs.core.windows.net/", local.data_layers[0].storage_container, var.azurerm_storage_account_unity_catalog.name)
  credential_name = databricks_storage_credential.external_mi.id
  owner           = "account_unity_admin"
  comment         = "External location for landing container"
}

resource "databricks_external_location" "bronze" {
  name            = local.data_layers[1].external_location
  url             = format("abfss://%s@%s.dfs.core.windows.net/", local.data_layers[1].storage_container, var.azurerm_storage_account_unity_catalog.name)
  credential_name = databricks_storage_credential.external_mi.id
  owner           = "account_unity_admin"
  comment         = "External location for bronze container"
}

resource "databricks_external_location" "silver" {
  name            = local.data_layers[2].external_location
  url             = format("abfss://%s@%s.dfs.core.windows.net/", local.data_layers[2].storage_container, var.azurerm_storage_account_unity_catalog.name)
  credential_name = databricks_storage_credential.external_mi.id
  owner           = "account_unity_admin"
  comment         = "External location for silver container"
}

resource "databricks_external_location" "gold" {
  name            = local.data_layers[3].external_location
  url             = format("abfss://%s@%s.dfs.core.windows.net/", local.data_layers[3].storage_container, var.azurerm_storage_account_unity_catalog.name)
  credential_name = databricks_storage_credential.external_mi.id
  owner           = "account_unity_admin"
  comment         = "External location for gold container"
}

resource "databricks_external_location" "checkpoint" {
  name            = local.data_layers[4].external_location
  url             = format("abfss://%s@%s.dfs.core.windows.net/", local.data_layers[4].storage_container, var.azurerm_storage_account_unity_catalog.name)
  credential_name = databricks_storage_credential.external_mi.id
  owner           = "account_unity_admin"
  comment         = "External location for checkpoint container"
}

# Create a catalog associated with the landing external location
resource "databricks_catalog" "environment" {
  metastore_id = var.metastore_id
  name         = local.catalog_name
  comment      = "Catalog for ${local.environment} environment"
  owner        = "account_unity_admin"

  storage_root = replace(databricks_external_location.landing.url, "/$", "")

  properties = {
    purpose = var.environment
  }
}

# Apply catalog-level grants
resource "databricks_grants" "environment_catalog" {
  catalog = databricks_catalog.environment.name

  # Standard grants for all roles
  grant {
    principal  = "data_engineer"
    privileges = ["USE_CATALOG"]
  }

  grant {
    principal  = "data_scientist"
    privileges = ["USE_CATALOG"]
  }

  grant {
    principal  = "data_analyst"
    privileges = ["USE_CATALOG"]
  }
}

# Create schemas explicitly for each data layer
# Bronze, Silver, Gold
resource "databricks_schema" "bronze_schema" {
  catalog_name = databricks_catalog.environment.id
  name         = local.data_layers[1].name
  owner        = "account_unity_admin"
  comment      = "Schema for bronze layer in ${local.catalog_name}"
}

resource "databricks_schema" "silver_schema" {
  catalog_name = databricks_catalog.environment.id
  name         = local.data_layers[2].name
  owner        = "account_unity_admin"
  comment      = "Schema for silver layer in ${local.catalog_name}"
}

resource "databricks_schema" "gold_schema" {
  catalog_name = databricks_catalog.environment.id
  name         = local.data_layers[3].name
  owner        = "account_unity_admin"
  comment      = "Schema for gold layer in ${local.catalog_name}"
}

# Grant permissions on each schema
# Bronze SIlver Gold
resource "databricks_grants" "bronze_schema_permissions" {
  schema = databricks_schema.bronze_schema.id

  # Standard grants for bronze schema
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }

  grant {
    principal  = "data_scientist"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
}

resource "databricks_grants" "silver_schema_permissions" {
  schema = databricks_schema.silver_schema.id

  # Standard grants for silver schema
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }

  grant {
    principal  = "data_scientist"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
}

resource "databricks_grants" "gold_schema_permissions" {
  schema = databricks_schema.gold_schema.id

  # Standard grants for gold schema
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }

  grant {
    principal  = "data_scientist"
    privileges = ["USE_SCHEMA", "SELECT"]
  }

  # Additional grants for data_analyst on the gold schema
  grant {
    principal  = "data_analyst"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
}