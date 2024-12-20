// Create azure managed identity to be used by unity catalog metastore
resource "azurerm_databricks_access_connector" "unity" {
  name                = "${var.prefix}-databricks-mi"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  identity {
    type = "SystemAssigned"
  }
}

# Generate a random string for uniqueness
resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

// Create a storage account to be used by unity catalog metastore as root storage
resource "azurerm_storage_account" "unity_catalog" {
  name                     = substr(lower(replace("databrickssa${random_string.unique.result}", "/[^a-z0-9]/", "")), 0, 24)
  resource_group_name      = var.resource_group
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  is_hns_enabled                  = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  identity {
    type = "SystemAssigned"
  }
}

// Create a container in storage account to be used by unity catalog metastore as root storage
resource "azurerm_storage_container" "unity_catalog" {
  name                  = "${var.prefix}-container"
  storage_account_name  = azurerm_storage_account.unity_catalog.name
  container_access_type = "private"
}

// Assign the Storage Blob Data Contributor role to managed identity to allow unity catalog to access the storage
resource "azurerm_role_assignment" "mi_data_contributor" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

// Create the first unity catalog metastore
// This throws an error because there will be metasotre created in that region during workspace creation
// Only one metastore can be created in a region
// I deleted the existing one at https://accounts.azuredatabricks.net/ workspaces
// I had to delete the existing one rerun this script
resource "databricks_metastore" "this" {
  name = var.metastore_name
  storage_root = format("abfss://%s@%s.dfs.core.windows.net/",
    azurerm_storage_container.unity_catalog.name,
  azurerm_storage_account.unity_catalog.name)
  force_destroy = true
  owner         = "account_unity_admin"
}

# Introduce a delay after metastore creation
resource "time_sleep" "wait_30_seconds" {
  depends_on = [databricks_metastore.this]

  create_duration = "30s"
}

// Assign managed identity to metastore, 
resource "databricks_metastore_data_access" "first" {
  metastore_id = databricks_metastore.this.id
  name         = "the-metastore-key"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity.id
  }
  is_default = true

  depends_on = [time_sleep.wait_30_seconds]
}

// Attach the databricks workspace to the metastore
resource "databricks_metastore_assignment" "this" {
  workspace_id         = var.databricks_workspace_id
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

// Add groups to databricks account
resource "databricks_group" "this" {
  provider     = databricks.azure_account
  for_each     = data.azuread_group.this
  display_name = each.key
  external_id  = data.azuread_group.this[each.key].object_id
  force        = true
}

// All governed by AzureAD, create or remove users to/from databricks account
resource "databricks_user" "this" {
  provider                 = databricks.azure_account
  for_each                 = local.all_users
  user_name                = lower(local.all_users[each.key]["user_principal_name"])
  display_name             = local.all_users[each.key]["display_name"]
  active                   = local.all_users[each.key]["account_enabled"]
  external_id              = each.key
  force                    = true
  disable_as_user_deletion = true # default behavior

  // Review warning before deactivating or deleting users from databricks account
  // https://learn.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/scim/#add-users-and-groups-to-your-azure-databricks-account-using-azure-active-directory-azure-ad
  lifecycle {
    prevent_destroy = false
  }
}

// All governed by AzureAD, create or remove service to/from databricks account
resource "databricks_service_principal" "sp" {
  provider       = databricks.azure_account
  for_each       = local.all_spns
  application_id = local.all_spns[each.key]["application_id"]
  display_name   = local.all_spns[each.key]["display_name"]
  active         = local.all_spns[each.key]["account_enabled"]
  external_id    = each.key
  force          = true
}

// Making all users on account_unity_admin group as databricks account admin
resource "databricks_user_role" "account_admin" {
  provider   = databricks.azure_account
  for_each   = local.all_account_admin_users
  user_id    = databricks_user.this[each.key].id
  role       = "account_admin"
  depends_on = [databricks_group.this, databricks_user.this, databricks_service_principal.sp]
}
