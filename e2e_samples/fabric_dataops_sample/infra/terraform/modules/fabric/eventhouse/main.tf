terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

resource "fabric_eventhouse" "eventhouse" {
  display_name = var.eventhouse_name
  description  = var.eventhouse_description
  workspace_id = var.workspace_id
}
