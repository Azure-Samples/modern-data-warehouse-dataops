resource "azapi_resource" "fab_capacity" {
  count                     = var.create_fabric_capacity ? 1 : 0
  type                      = "Microsoft.Fabric/capacities@2023-11-01"
  name                      = var.capacity_name
  parent_id                 = var.resource_group_id
  location                  = var.location
  schema_validation_enabled = false

  body = jsonencode({
    properties = {
      administration = {
        members = var.admin_members
      }
    }
    sku = {
      name = var.sku,
      tier = "Fabric"
    }
  })

  tags                    = var.tags
  ignore_missing_property = true
}

data "fabric_capacity" "created_capacity_id" {
  count        = var.create_fabric_capacity ? 1 : 0
  display_name = resource.azapi_resource.fab_capacity[0].name
}

data "fabric_capacity" "provided_capacity_id" {
  count        = var.create_fabric_capacity ? 0 : 1
  display_name = var.capacity_name
}
