output "spark_custom_pool_id" {
  value       = fabric_spark_custom_pool.spark_custom_pool.id
  description = "The ID of the created Spark custom pool"
}

output "spark_custom_pool_name" {
  value       = fabric_spark_custom_pool.spark_custom_pool.name
  description = "The name of the created Spark custom pool"
}
