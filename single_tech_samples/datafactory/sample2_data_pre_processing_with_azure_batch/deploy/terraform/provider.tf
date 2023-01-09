terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.22.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}
