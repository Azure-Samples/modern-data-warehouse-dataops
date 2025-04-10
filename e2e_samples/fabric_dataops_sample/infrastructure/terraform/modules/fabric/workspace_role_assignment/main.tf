resource "fabric_workspace_role_assignment" "role_assigment" {
  workspace_id = var.workspace_id
  principal = {
    id   = var.principal_id
    type = var.principal_type
  }
  role = var.role
}
