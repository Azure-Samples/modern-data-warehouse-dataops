resource "azurerm_role_assignment" "role_assignment" {
  principal_id         = var.principal_id
  role_definition_name = var.role_definition_name
  scope                = var.scope
}
