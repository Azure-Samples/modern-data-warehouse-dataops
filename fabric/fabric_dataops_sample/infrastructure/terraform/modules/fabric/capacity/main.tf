resource "azurerm_fabric_capacity" "capacity" {
  count                  = var.create_fabric_capacity ? 1 : 0
  name                   = var.capacity_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administration_members = var.admin_members

  sku {
    name = var.sku
    tier = "Fabric"
  }
  tags = var.tags
}

data "fabric_capacity" "created_capacity_id" {
  count        = var.create_fabric_capacity ? 1 : 0
  display_name = resource.azurerm_fabric_capacity.capacity[0].name

  lifecycle {
    postcondition {
      condition     = self.state == "Active"
      error_message = "Fabric Capacity is not in Active state. Please check the Fabric Capacity status."
    }
  }
}

data "fabric_capacity" "provided_capacity_id" {
  count        = var.create_fabric_capacity ? 0 : 1
  display_name = var.capacity_name

  lifecycle {
    postcondition {
      condition     = self.state == "Active"
      error_message = "Fabric Capacity is not in Active state. Please check the Fabric Capacity status."
    }
  }
}
