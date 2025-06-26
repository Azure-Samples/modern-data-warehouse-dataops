variable "enable" {
  type        = bool
  description = "whether this module should do anything at all"
  default     = false
}

variable "workspace_id" {
  description = "Microsoft Fabric workspace id"
  type        = string
}

variable "environment_name" {
  description = "Microsoft Fabric environment display name"
  type        = string
}

variable "environment_description" {
  description = "Microsoft Fabric environment description"
  type        = string
}
