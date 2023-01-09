resource "azurerm_user_assigned_identity" "managed_identity" {
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  name = "${var.resource_group_name}-${var.name_suffix}"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
