terraform {
  required_version = ">= 1.9.8, < 2.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.9.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }
    azapi = {
      source  = "azure/azapi"
      version = "2.0.1"
    }
    azuredevops = {
      source = "microsoft/azuredevops"
      version = "1.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
