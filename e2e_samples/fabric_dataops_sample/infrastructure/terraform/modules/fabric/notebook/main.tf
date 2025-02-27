resource "fabric_notebook" "notebook" {
  count        = var.enable ? 1 : 0
  display_name = var.notebook_name
  description  = var.notebook_description
  workspace_id = var.workspace_id
  format       = var.format
  definition = {
    "notebook-content.ipynb" = {
      source = var.notebook_definition_path
      tokens = var.tokens
    }
  }
  definition_update_enabled = var.definition_update_enabled
}
