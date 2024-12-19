variable "enable" {
  type        = bool
  description = "whether this module should do anything at all"
  default     = false
}

variable "workspace_id" {
  type        = string
  description = "Fabric workspace id"
}

variable "environment_name" {
  type        = string
  description = "Fabric environment name"
}

variable "default_pool_name" {
  type        = string
  description = "Default pool name"
}

variable "runtime_version" {
  type        = string
  description = "Fabric environment runtime version"
  default     = "1.3"
}

variable "default_pool_type" {
  type        = string
  description = "Default pool type"
  default     = "Workspace"
}

variable "starter_pool_max_node_count" {
  type        = number
  description = "The maximum node count for the starter pool"
  default     = 2
}

variable "starter_pool_max_executors" {
  type        = number
  description = "The maximum number of executors for the starter pool"
  default     = 1
}

variable "customize_compute_enabled" {
  type        = bool
  description = "Whether customized compute is enabled"
  default     = true
}

variable "automatic_log_enabled" {
  type        = bool
  description = "Whether automatic logging is enabled"
  default     = true
}

variable "notebook_interactive_run_enabled" {
  type        = bool
  description = "Whether notebook interactive run is enabled for high concurrency"
  default     = true
}
