variable "workspace_id" {
  description = "Microsoft Fabric workspace id"
  type        = string
}

variable "database_name" {
  description = "Microsoft Fabric kql database display name"
  type        = string
}

variable "database_description" {
  description = "Microsoft Fabric kql database description"
  type        = string
  default     = null
}

variable "database_type" {
  description = "Microsoft Fabric kql database type"
  type        = string
  default     = "ReadWrite"
}

variable "eventhouse_id" {
  description = "Microsoft Fabric eventhouse id"
  type        = string
  default     = null
}

variable "source_database_name" {
  description = "Microsoft Fabric kql database source database name"
  type        = string
  default     = null
}

variable "source_cluster_uri" {
  description = "Microsoft Fabric kql database source cluster uri"
  type        = string
  default     = null
}
