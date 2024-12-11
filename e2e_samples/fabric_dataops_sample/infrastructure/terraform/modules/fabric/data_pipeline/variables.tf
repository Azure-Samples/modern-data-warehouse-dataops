variable "enable" {
  type        = bool
  description = "whether this module should do anything at all"
  default     = false
}

variable "workspace_id" {
  description = "Microsoft Fabric workspace id"
  type        = string
}

variable "data_pipeline_name" {
  description = "Microsoft Fabric data pipeline display name"
  type        = string
}

variable "data_pipeline_description" {
  description = "Microsoft Fabric data pipeline description"
  type        = string
  default     = ""
}

variable "data_pipeline_definition_path" {
  description = "The path to the 'json' data pipeline file"
  type        = string
}

variable "tokens" {
  description = "The tokens to be used in the notebook"
  type        = map(string)
  default     = {}
}

variable "definition_update_enabled" {
  description = "Update definition on change of source content."
  type        = bool
  default     = true
}
