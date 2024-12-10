resource "fabric_lakehouse" "lakehouse" {
  display_name = var.lakehouse_name
  description  = var.lakehouse_description
  workspace_id = var.workspace_id
  configuration = {
    enable_schemas = var.enable_schemas
  }
}
