resource "fabric_lakehouse" "warehouse" {
  display_name = var.warehouse_name
  description  = var.warehouse_description
  workspace_id = var.workspace_id
}
