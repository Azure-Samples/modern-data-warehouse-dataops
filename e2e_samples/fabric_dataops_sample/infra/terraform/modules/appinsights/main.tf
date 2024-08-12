resource "azurerm_application_insights" "appinsights" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.workspace_id
  application_type    = var.application_type
  tags                = var.tags
}