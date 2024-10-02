terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.3"
    }
  }
}

resource "fabric_domain_role_assignments" "domain_role_assignments" {
  domain_id  = var.domain_id
  role       = var.role
  principals = var.principals
}
