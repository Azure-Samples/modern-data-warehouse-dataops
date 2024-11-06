terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.37.0"
    }
  }
}

resource "azurerm_storage_account" "adls" {
  name                     = "${var.data_lake_store_name}${var.tags.environment}${var.adls_suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  is_hns_enabled           = var.is_hns_enabled
  nfsv3_enabled            = var.nfsv3_enabled
  tags                     = var.tags
  blob_properties {
    last_access_time_enabled = var.last_access_time_enabled

    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "OPTIONS"]
      allowed_origins    = var.blob_storage_cors_origins
      exposed_headers    = ["*"]
      max_age_in_seconds = 0
    }
  }
  network_rules {
    default_action             = var.default_action
    bypass                     = var.bypass
    virtual_network_subnet_ids = [var.virtual_network_subnet_id]
  }
}

# The azurerm_storage_container resource block can not be used due to a bug in the terraform provider 
# Hence the deployment is done using ARM template for storage containers

resource "azurerm_resource_group_template_deployment" "storage-containers" {
  name                = var.container_name
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  depends_on = [
    azurerm_storage_account.adls
  ]

  parameters_content = jsonencode({
    "location"             = { value = var.location }
    "storageAccountName"   = { value = azurerm_storage_account.adls.name }
    "defaultContainerName" = { value = var.container_name }
  })

  template_content = file("${path.module}/storage-container.json")
}
