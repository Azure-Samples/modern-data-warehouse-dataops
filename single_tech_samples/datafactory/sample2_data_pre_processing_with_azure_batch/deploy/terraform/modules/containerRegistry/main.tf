resource "random_string" "acr_suffix" {
  keepers = {
    "acr_name" = var.acr_name
  }
  length  = 8
  special = false
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.acr_name}${random_string.acr_suffix.id}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = var.tags
  identity {
    type = "UserAssigned"
    identity_ids = [var.batch_uami_id]
  }
}
