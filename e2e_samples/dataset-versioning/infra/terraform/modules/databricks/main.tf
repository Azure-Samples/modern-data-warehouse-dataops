resource "azurerm_databricks_workspace" "databricks" {
  name                = "dbw-${var.app_name}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = var.sku

  tags = {
    "iac" = "terraform"
  }
}
