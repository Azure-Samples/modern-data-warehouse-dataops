resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.region
}

resource "azurerm_databricks_workspace" "this" {
  name                        = var.resource_group_name
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  depends_on                  = [ azurerm_resource_group.this ]
}

