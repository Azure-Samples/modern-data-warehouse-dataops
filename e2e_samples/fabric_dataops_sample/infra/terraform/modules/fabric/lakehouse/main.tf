terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

resource "fabric_lakehouse" "lakehouse" {
  display_name = var.lakehouse_name
  description  = var.lakehouse_description
  workspace_id = var.workspace_id
}