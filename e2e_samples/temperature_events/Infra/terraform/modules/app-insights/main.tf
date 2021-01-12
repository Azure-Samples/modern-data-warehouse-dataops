resource "azurerm_application_insights" "app_insights" {
  name                = "appi-${var.resource_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.appinsights_application_type
  retention_in_days   = var.retention
}
