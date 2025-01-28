output "spark_workspace_settings_id" {
  value       = var.enable ? fabric_spark_workspace_settings.settings[0].id : ""
  description = "Fabric spark workspace settings id"
}
