resource "fabric_workspace_role_assignment" "role_assigment" {
  workspace_id   = var.workspace_id
  principal_id   = var.principal_id
  principal_type = var.principal_type
  role           = var.role
}
