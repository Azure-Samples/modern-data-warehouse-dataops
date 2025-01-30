output "data_pipeline_id" {
  value       = var.enable ? fabric_data_pipeline.data_pipeline[0].id : ""
  description = "Microsoft Fabric data pipeline id"
}

output "data_pipeline_name" {
  value       = var.enable ? fabric_data_pipeline.data_pipeline[0].display_name : ""
  description = "Microsoft Fabric data pipeline display name"
}
