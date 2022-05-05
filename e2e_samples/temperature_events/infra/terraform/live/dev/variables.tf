# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "environment" {
  type        = string
  description = "The name of the environment we're deploying to"
  default     = "dev"
}


variable "location" {
  type        = string
  description = "Azure Location of the service"
  default     = "eastus2"
}

variable "eventhub_config" {
  type = object({
    sku               = string
    capacity          = number
    max_capacity      = number
    partition_count   = number
    message_retention = number
  })
  description = "Configuration for Eventhubs assuming all Eventhubs have exact same configuration"
  default = {
    sku               = "Standard"
    capacity          = 1
    max_capacity      = 1
    partition_count   = 2
    message_retention = 1
  }
}

variable "name" {
  type        = string
  description = "The name of service"
  default     = "tempevt"
}

variable "kv_sku" {
  type        = string
  description = "SKU of the Keyvault to create"
  default     = "standard"
}
