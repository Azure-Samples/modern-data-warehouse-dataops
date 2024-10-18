terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

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

  tags = var.tags
}

data "fabric_capacity" "created_capacity_id" {
  count = var.create_fabric_capacity ? 1 : 0
  display_name = resource.azapi_resource.fab_capacity.name
}

data "fabric_capacity" "provided_capacity_id" {
  count = var.create_fabric_capacity ? 0 : 1
  id = var.fabric_capacity_id
}