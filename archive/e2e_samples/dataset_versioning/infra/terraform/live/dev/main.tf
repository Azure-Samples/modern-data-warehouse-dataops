terraform {
  backend "azurerm" {
  }
  required_version = ">= 0.14.5"
}

provider "azurerm" {
  # Set partner ID for telemetry. For usage details, see https://github.com/microsoft/modern-data-warehouse-dataops/blob/main/README.md#data-collection
  partner_id                 = "acce1e78-f4d8-403c-a3f8-7a0ac57cc49c"
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
