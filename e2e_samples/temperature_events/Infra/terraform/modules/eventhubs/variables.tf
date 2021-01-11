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
  description = "Resource group name that the service uses"
  type        = string
}

variable "eventhub_name" {
  description = "String value appended to the name of each eventhub"
  type        = string
}

variable "resource_name" {
  description = "Name of this service"
  type        = string
}

variable "location" {
  description = "Location where eventhub is provisioned to"
  type        = string
}
