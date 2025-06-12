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
  features {
    key_vault {
      recover_soft_deleted_key_vaults = false
      purge_soft_delete_on_destroy    = true
    }
  }
  
  # Partner ID for telemetry tracking
  partner_id = "acce1e78-XXXX-XXXX-XXXX-XXXXXXXXXXXXX"  # Replace with unique GUID for adf_data_pre_processing_with_azure_batch sample
}
