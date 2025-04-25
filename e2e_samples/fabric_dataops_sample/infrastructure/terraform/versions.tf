terraform {
  required_version = ">= 1.9.8, < 2.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "1.1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.27.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.3.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "1.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
