terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.37.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  # Set partner ID for telemetry. For usage details, see https://github.com/microsoft/modern-data-warehouse-dataops/blob/main/README.md#data-collection
  partner_id = "acce1e78-dcd0-37e3-4ff3-1ec1a177be51"
  features {
    key_vault {
      recover_soft_deleted_key_vaults = false
      purge_soft_delete_on_destroy    = true
    }
  }
}
