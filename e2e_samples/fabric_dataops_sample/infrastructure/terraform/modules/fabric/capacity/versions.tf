terraform {
  required_version = ">= 1.9.8, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.23.0"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-rc.1"
    }
  }
}
