terraform {
  backend "azurerm" {
  }
  required_version = ">= 0.14.5"
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

module "service" {
  source   = "../../modules/service"
  rg_name  = var.rg_name
  env      = var.env
  app_name = var.app_name
  location = var.location
}
