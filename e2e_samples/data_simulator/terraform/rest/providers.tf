terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.86.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "0000000-0000-00000-000000"
}