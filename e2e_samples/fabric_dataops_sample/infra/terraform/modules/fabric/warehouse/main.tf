terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.3"
    }
  }
}

resource "fabric_lakehouse" "warehouse" {
  display_name = var.warehouse_name
  description  = var.warehouse_description
  workspace_id = var.workspace_id
}