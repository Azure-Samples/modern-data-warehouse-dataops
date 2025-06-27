resource "azurerm_container_registry" "acr" {
  name                = "${var.acr_name}${var.tags.environment}${var.acr_suffix}"
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
