output "spark_environment_settings_id" {
  value = var.enable ? fabric_spark_environment_settings.spark_env_settings[0].id : ""
}

output "spark_environment_settings_workspace_id" {
  value = var.enable ? fabric_spark_environment_settings.spark_env_settings[0].workspace_id : ""
}

output "spark_environment_settings_environment_id" {
  value = var.enable ? fabric_spark_environment_settings.spark_env_settings[0].environment_id : ""
}

output "spark_environment_settings_runtime_version" {
  value = var.enable ? fabric_spark_environment_settings.spark_env_settings[0].runtime_version : ""
}
