resource "fabric_workspace" "workspace" {
  display_name = var.workspace_name
  description  = var.workspace_description
  capacity_id  = var.capacity_id
  identity = {
    type = var.workspace_identity_type
  }
}
