terraform {
  backend "azurerm" {
  }
  required_version = ">= 0.13"
}

provider "azurerm" {
  client_id                   = var.client_id
  client_secret               = var.client_secret
  subscription_id             = var.subscription_id
  tenant_id                   = var.tenant_id
  skip_credentials_validation = true

  version = "~> 2.39.0"
  features {}
}

module "service" {
  source = "../../modules/services"

  location        = var.location
  environment     = var.environment
  eventhub_config = var.eventhub_config
  kv_sku          = var.kv_sku
}
