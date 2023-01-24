terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.22.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.11"
    }
  }
    required_version = ">= 1.3"
}

provider "azurerm" {
  # Configuration options
  features {}
}

