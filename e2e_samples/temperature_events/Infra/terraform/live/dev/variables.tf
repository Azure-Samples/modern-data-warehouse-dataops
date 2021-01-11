# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "client_id" {
  type        = string
  description = "Client id (application id) of your service service principal"
}

variable "client_secret" {
  type        = string
  description = "Secret of service principal"
}

variable "subscription_id" {
  type        = string
  description = "Your Azure subscription id"
}

variable "tenant_id" {
  type        = string
  description = "Your Azure tenant id"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "environment" {
  description = "The name of the environment we're deploying to"
  type        = string
  default     = "dev"
}


variable "location" {
  description = "Azure Location of the service"
  default     = "eastus2"
  type        = string
}

variable "eventhub_config" {
  type = object({
    sku               = string
    capacity          = number
    max_capacity      = number
    partition_count   = number
    message_retention = number
  })
  default = {
    sku               = "Standard"
    capacity          = 1
    max_capacity      = 1
    partition_count   = 2
    message_retention = 1
  }
  description = "Configuration for Eventhubs assuming all Eventhubs have exact same configuration"
}

variable "kv_sku" {
  type        = string
  default     = "standard"
  description = "SKU of the Keyvault to create"
}
