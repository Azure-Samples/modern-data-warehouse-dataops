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
  subscription_id = "<your-subscription-id>"
}