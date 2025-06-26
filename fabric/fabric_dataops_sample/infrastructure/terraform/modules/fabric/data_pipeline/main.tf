resource "fabric_data_pipeline" "data_pipeline" {
  count        = var.enable ? 1 : 0
  display_name = var.data_pipeline_name
  description  = var.data_pipeline_description
  workspace_id = var.workspace_id
  format       = var.format
  definition = {
    "pipeline-content.json" = {
      source = var.data_pipeline_definition_path
      tokens = var.tokens
    }
  }
  definition_update_enabled = var.definition_update_enabled
}
