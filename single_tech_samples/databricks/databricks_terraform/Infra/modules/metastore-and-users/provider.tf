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
  subscription_id = var.subscription_id
  features {}
  storage_use_azuread = true
  
  # Partner ID for telemetry tracking
  partner_id = "acce1e78-XXXX-XXXX-XXXX-XXXXXXXXXXXXX"  # Replace with unique GUID for databricks_terraform sample
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