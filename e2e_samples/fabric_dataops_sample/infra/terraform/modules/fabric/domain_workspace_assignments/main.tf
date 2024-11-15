terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

resource "fabric_domain_workspace_assignments" "domain_workspace_assignments" {
  domain_id     = var.domain_id
  workspace_ids = var.workspace_ids
}
