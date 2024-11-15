resource "fabric_environment" "environment" {
  display_name = var.environment_name
  description  = var.environment_description
  workspace_id = var.workspace_id
}
