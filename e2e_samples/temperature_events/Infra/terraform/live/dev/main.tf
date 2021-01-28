terraform {
  backend "azurerm" {
  }
  required_version = ">= 0.13"
}

provider "azurerm" {
  skip_credentials_validation = true
  features {}
}

module "service" {
  source = "../../modules/services"

  location        = var.location
  environment     = var.environment
  eventhub_config = var.eventhub_config
  kv_sku          = var.kv_sku
  name            = var.name
}
