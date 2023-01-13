resource "azurerm_user_assigned_identity" "managed_identity" {
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  name = "${var.name_suffix}-managed-identity"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
