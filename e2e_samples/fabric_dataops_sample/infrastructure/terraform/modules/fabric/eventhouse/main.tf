resource "fabric_eventhouse" "eventhouse" {
  display_name = var.eventhouse_name
  description  = var.eventhouse_description
  workspace_id = var.workspace_id
}
