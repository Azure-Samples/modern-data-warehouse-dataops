variable "workspace_id" {
  description = "Microsoft Fabric workspace id"
  type        = string
}

variable "lakehouse_name" {
  description = "Microsoft Fabric lakehouse display name"
  type        = string
}

variable "lakehouse_description" {
  description = "Microsoft Fabric lakehouse description"
  type        = string
}

variable "enable_schemas" {
  description = "Enable schemas in the Lakehouse"
  type        = bool
  default     = true
}
