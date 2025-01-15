resource "fabric_spark_workspace_settings" "settings" {
  count        = var.enable ? 1 : 0
  workspace_id = var.workspace_id

  automatic_log = {
    enabled = var.automatic_log_enabled
  }

  high_concurrency = {
    notebook_interactive_run_enabled = var.notebook_interactive_run_enabled
  }

  environment = {
    name            = var.environment_name
    runtime_version = var.runtime_version
  }

  pool = {
    default_pool = {
      name = var.default_pool_name
      type = var.default_pool_type
    }
    starter_pool = {
      max_executors  = var.starter_pool_max_executors
      max_node_count = var.starter_pool_max_node_count
    }
    customize_compute_enabled = var.customize_compute_enabled
  }
}
