terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "random" {}
provider "azuread" {
  tenant_id = var.tenant_id
}

provider "fabric" {
  use_cli       = var.use_cli
  use_msi       = var.use_msi
  tenant_id     = var.tenant_id
  client_id     = var.use_msi || var.use_cli ? null : var.client_id
  client_secret = var.use_msi || var.use_cli ? null : var.client_secret
}

provider "azurerm" {
  tenant_id                       = var.tenant_id
  subscription_id                 = var.subscription_id
  client_id                       = var.use_msi || var.use_cli ? null : var.client_id
  client_secret                   = var.use_msi || var.use_cli ? null : var.client_secret
  use_msi                         = var.use_msi
  use_cli                         = var.use_cli
  storage_use_azuread             = true
  resource_provider_registrations = "none"
  features {}
}

provider "azapi" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.use_msi || var.use_cli ? null : var.client_id
  client_secret   = var.use_msi || var.use_cli ? null : var.client_secret
  use_msi         = var.use_msi
  use_cli         = var.use_cli
}
