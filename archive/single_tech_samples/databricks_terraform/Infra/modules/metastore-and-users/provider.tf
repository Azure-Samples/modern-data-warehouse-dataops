terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "azurerm" {
  # Set partner ID for telemetry. For usage details, see https://github.com/microsoft/modern-data-warehouse-dataops/blob/main/README.md#data-collection
  partner_id          = "acce1e78-babd-6b30-049f-9496f0518a8f"
  subscription_id     = var.subscription_id
  features {}
  storage_use_azuread = true
}

// Provider for databricks workspace
provider "databricks" {
  host = var.databricks_workspace_host_url
}

// Initialize provider at Azure account-level
provider "databricks" {
  alias      = "azure_account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.account_id
  auth_type  = "azure-cli"
}