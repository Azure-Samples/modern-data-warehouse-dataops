terraform {
  required_version = ">= 1.9.8, < 2.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-rc.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.23.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.1.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "1.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
  }
}
