terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.3"
    }
  }
}

resource "fabric_workspace" "workspace" {
  display_name = var.workspace_name
  description  = var.workspace_description
  capacity_id  = var.capacity_id
  identity = {
    type = var.workspace_identity_type
  }
}
