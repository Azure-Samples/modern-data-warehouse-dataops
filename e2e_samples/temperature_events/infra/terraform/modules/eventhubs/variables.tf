# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "eventhub_config" {
  type = object({
    sku               = string
    capacity          = number
    max_capacity      = number
    partition_count   = number
    message_retention = number
  })
  description = "Configuration for eventhub"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name that the service uses"
}

variable "eventhub_name" {
  type        = string
  description = "String value appended to the name of each eventhub"
}

variable "resource_name" {
  type        = string
  description = "Name of this service"
}

variable "location" {
  type        = string
  description = "Location where eventhub is provisioned to"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "function_consumer_group" {
  type        = string
  description = "Name of consumer group"
  default     = "functions"
}

variable "authorization_rule" {
  type        = string
  description = "Name of authorization rule"
  default     = "authorization_rule"
}
