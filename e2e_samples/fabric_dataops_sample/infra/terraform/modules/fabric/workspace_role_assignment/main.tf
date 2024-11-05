terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

resource "fabric_workspace_role_assignment" "role_assigment" {
  workspace_id   = var.workspace_id
  principal_id   = var.principal_id
  principal_type = var.principal_type
  role           = var.role
}
