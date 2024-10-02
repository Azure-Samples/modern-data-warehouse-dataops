variable "workspace_id" {
  type        = string
  description = "Fabric workspace id"
}

variable "environment_id" {
  description = "Microsoft Fabric environment id"
  type        = string
}

variable "publication_status" {
  description = "Microsoft Fabric environment publication status"
  type        = string
  default     = "Published"
}

variable "spark_pool_name" {
  type        = string
  description = "Workspace default Spark pool name"
  default     = "Starter Pool"
}

variable "spark_pool_type" {
  type        = string
  description = "Workspace default Spark pool type"
  default     = "Workspace"
}

variable "runtime_version" {
  type        = string
  description = "Fabric environment runtime version"
  default     = "1.2"
}