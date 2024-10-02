terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.3"
    }
  }
}

resource "fabric_domain" "domain" {
  display_name       = var.domain_name
  description        = var.domain_description
  contributors_scope = var.contributors_scope != null ? var.contributors_scope : null
  parent_domain_id   = var.parent_domain_id != null ? var.parent_domain_id : null
}
