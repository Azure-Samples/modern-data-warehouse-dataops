terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

resource "fabric_environment" "environment" {
  display_name = var.environment_name
  description  = var.environment_description
  workspace_id = var.workspace_id
}