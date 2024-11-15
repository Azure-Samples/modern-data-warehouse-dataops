resource "fabric_domain_role_assignments" "domain_role_assignments" {
  domain_id  = var.domain_id
  role       = var.role
  principals = var.principals
}
