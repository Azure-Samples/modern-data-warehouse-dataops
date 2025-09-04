terraform {
  backend "azurerm" {
  }
  required_version = ">= 0.13"
}

provider "azurerm" {
  # Set partner ID for telemetry. For usage details, see https://github.com/microsoft/modern-data-warehouse-dataops/blob/main/README.md#data-collection
  partner_id = "acce1e78-f4d8-403c-a3f8-7a0ac57cc49c"
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
