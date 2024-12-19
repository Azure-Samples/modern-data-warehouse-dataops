resource "fabric_domain_workspace_assignments" "domain_workspace_assignments" {
  domain_id     = var.domain_id
  workspace_ids = var.workspace_ids
}
