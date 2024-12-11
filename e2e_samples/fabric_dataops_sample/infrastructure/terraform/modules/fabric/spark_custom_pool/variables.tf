variable "workspace_id" {
  type        = string
  description = "Microsoft Fabric workspace id"
}

variable "custom_pool_name" {
  type        = string
  description = "Spark custom pool name"
}

variable "node_family" {
  type        = string
  description = "The node family for the Spark custom pool"
  default     = "MemoryOptimized"
}

variable "node_size" {
  type        = string
  description = "The node size for the Spark custom pool"
  default     = "Small"
}

variable "auto_scale_enabled" {
  type        = bool
  description = "Whether auto-scaling is enabled"
  default     = true
}

variable "auto_scale_min_node_count" {
  type        = number
  description = "The minimum node count for auto-scaling"
  default     = 1
}

variable "auto_scale_max_node_count" {
  type        = number
  description = "The maximum node count for auto-scaling"
  default     = 3
}

variable "dynamic_executor_allocation_enabled" {
  type        = bool
  description = "Whether dynamic executor allocation is enabled"
  default     = true
}

variable "dynamic_executor_allocation_min_executors" {
  type        = number
  description = "The minimum number of executors for dynamic allocation"
  default     = 1
}

variable "dynamic_executor_allocation_max_executors" {
  type        = number
  description = "The maximum number of executors for dynamic allocation"
  default     = 2
}
