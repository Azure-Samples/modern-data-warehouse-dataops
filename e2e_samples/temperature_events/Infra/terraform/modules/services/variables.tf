# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "environment" {
  description = "The name of the environment we're deploying to"
  type        = string
}

variable "location" {
  description = "Azure Location of the service"
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
  description = "Configuration for Eventhubs assuming all Eventhubs have exact same configuration"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of service"
  default     = "tempevt"
  type        = string
}

variable "kv_sku" {
  type        = string
  description = "SKU of the Keyvault to create"
}

variable "event_hub_names" {
  default     = ["Ingress", "FilteredDevices", "TemperatureOutput", "TemperatureBadOutput"]
  type        = list(string)
  description = "List of string value appended to Eventhubs"
}

variable "functions_names" {
  type        = list(string)
  default     = ["listfilter", "tempfilter"]
  description = "List of string value appended to Azure Functions"
}
