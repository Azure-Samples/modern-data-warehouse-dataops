resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = var.region
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "${local.prefix}-ws"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = "${local.prefix}-ws-rg"
}

