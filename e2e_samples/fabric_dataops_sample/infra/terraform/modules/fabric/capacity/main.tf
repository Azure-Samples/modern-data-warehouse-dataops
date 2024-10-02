terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.3"
    }
  }
}

resource "azapi_resource" "fab_capacity" {
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

  tags = var.tags
}

data "fabric_capacity" "returned_capacity_id" {
  display_name = resource.azapi_resource.fab_capacity.name
}