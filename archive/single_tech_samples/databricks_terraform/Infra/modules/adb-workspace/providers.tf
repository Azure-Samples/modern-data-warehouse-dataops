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
  partner_id                 = "acce1e78-babd-6b30-049f-9496f0518a8f"
  features {}
  subscription_id            =  var.subscription_id
}
