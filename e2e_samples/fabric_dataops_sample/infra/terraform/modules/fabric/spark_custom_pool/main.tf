terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

resource "fabric_spark_custom_pool" "spark_custom_pool" {
  workspace_id = var.workspace_id
  name         = var.custom_pool_name
  node_family  = var.node_family
  node_size    = var.node_size
  type         = "Workspace"

  auto_scale = {
    enabled        = var.auto_scale_enabled
    min_node_count = var.auto_scale_min_node_count
    max_node_count = var.auto_scale_max_node_count
  }

  dynamic_executor_allocation = {
    enabled       = var.dynamic_executor_allocation_enabled
    min_executors = var.dynamic_executor_allocation_min_executors
    max_executors = var.dynamic_executor_allocation_max_executors
  }
}
