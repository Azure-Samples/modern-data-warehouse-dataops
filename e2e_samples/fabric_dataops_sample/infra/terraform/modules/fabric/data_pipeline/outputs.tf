output "data_pipeline_id" {
  value       = fabric_data_pipeline.data_pipeline.id
  description = "Microsoft Fabric data pipeline id"
}

output "data_pipeline_name" {
  value       = fabric_data_pipeline.data_pipeline.display_name
  description = "Microsoft Fabric data pipeline display name"
}